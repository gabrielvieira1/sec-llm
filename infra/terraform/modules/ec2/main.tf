# EC2 Module for DefectDojo
# This module creates EC2 instances optimized for DefectDojo deployment

# Data source to get the latest Amazon Linux 2023 AMI (recommended for AWS)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Alternative Ubuntu 24.04 LTS AMI (if preferred)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get default VPC subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Key pair for SSH access (using existing key in AWS)
# Create this key pair manually in AWS Console or via CLI:
# aws ec2 create-key-pair --key-name sec-llm-infra-defectdojo-key --query 'KeyMaterial' --output text > ~/.ssh/sec-llm-infra-defectdojo-key.pem
# chmod 400 ~/.ssh/sec-llm-infra-defectdojo-key.pem
data "aws_key_pair" "defectdojo_key" {
  key_name = "${var.project_name}-defectdojo-key"
}

# Launch template for DefectDojo instances
resource "aws_launch_template" "defectdojo" {
  name_prefix   = "${var.project_name}-defectdojo-"
  image_id      = data.aws_ami.amazon_linux.id # Using Amazon Linux 2023
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.defectdojo_key.key_name

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = var.iam_instance_profile_name # From security module
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-defectdojo"
      Type = "DefectDojo Server"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.project_name}-defectdojo-volume"
    })
  }

  tags = var.tags
}

# Single EC2 instance for DefectDojo
resource "aws_instance" "defectdojo" {
  launch_template {
    id      = aws_launch_template.defectdojo.id
    version = "$Latest"
  }

  subnet_id = data.aws_subnets.default.ids[0]

  tags = merge(var.tags, {
    Name = "${var.project_name}-defectdojo"
    Type = "DefectDojo Server"
  })
}

# S3 bucket for DefectDojo file uploads
resource "aws_s3_bucket" "defectdojo_uploads" {
  bucket = "${var.project_name}-defectdojo-uploads"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-defectdojo-uploads"
    Purpose = "DefectDojo file uploads"
  })
}

resource "aws_s3_bucket_versioning" "defectdojo_uploads" {
  bucket = aws_s3_bucket.defectdojo_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "defectdojo_uploads" {
  bucket = aws_s3_bucket.defectdojo_uploads.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "defectdojo_uploads" {
  bucket = aws_s3_bucket.defectdojo_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
