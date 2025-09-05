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

# Networking Module - Security Groups
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  tags         = local.common_tags
}

# Security Module - IAM roles and policies
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  web_allowed_cidrs = ["0.0.0.0/0"]
  tags              = local.common_tags
}

# RDS Module - PostgreSQL Database
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  security_group_ids = [module.networking.rds_security_group_id]
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
  security_group_ids        = [module.networking.defectdojo_security_group_id]
  iam_instance_profile_name = module.security.ecs_instance_profile_name
  database_url              = module.rds.database_url
  tags                      = local.common_tags

  depends_on = [aws_ssm_parameter.database_url]
}


