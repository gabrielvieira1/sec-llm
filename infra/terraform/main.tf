# Main Terraform Configuration for DefectDojo MVP
# Simplified setup using default VPC and single EC2 instance

# AWS Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "mvp"
    ManagedBy   = "Terraform"
    Owner       = "gabriel"
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Security Group for DefectDojo EC2 instance
resource "aws_security_group" "defectdojo" {
  name_prefix = "${var.project_name}-defectdojo-"
  description = "Security group for DefectDojo EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DefectDojo application port
  ingress {
    description = "DefectDojo App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-defectdojo-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for RDS database
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = data.aws_vpc.default.id

  # PostgreSQL access from DefectDojo EC2
  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.defectdojo.id]
  }

  # PostgreSQL access from external (para desenvolvimento local)
  ingress {
    description = "PostgreSQL external access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Para MVP - em produção, usar IPs específicos
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for EC2 to access SSM parameters
resource "aws_iam_role_policy" "ec2_ssm_policy" {
  name = "${var.project_name}-ec2-ssm-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}-*"
      }
    ]
  })
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# RDS Module - PostgreSQL Database
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.rds.id]
  instance_class     = var.db_instance_class
  db_password        = var.db_password
  tags               = local.common_tags
}

# Store database URL in SSM Parameter Store
resource "aws_ssm_parameter" "database_url" {
  name  = "${var.project_name}-database-url"
  type  = "SecureString"
  value = module.rds.database_url

  tags = local.common_tags
}

# EC2 Module - Single Instance for DefectDojo
module "ec2" {
  source = "./modules/ec2"

  project_name              = var.project_name
  instance_type             = var.instance_type
  security_group_ids        = [aws_security_group.defectdojo.id]
  iam_instance_profile_name = aws_iam_instance_profile.ec2_instance_profile.name
  database_url              = module.rds.database_url
  tags                      = local.common_tags

  depends_on = [aws_ssm_parameter.database_url]
}


