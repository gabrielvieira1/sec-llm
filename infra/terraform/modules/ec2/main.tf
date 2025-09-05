# EC2 Module for DefectDojo - Simplified Single Instance
# This module creates a single EC2 instance with DefectDojo installed via Docker

# Data source to get the latest Ubuntu 22.04 LTS AMI (more stable and widely available)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Key pair for SSH access (using existing key)
data "aws_key_pair" "defectdojo_key" {
  key_name = "sec-llm-infra-defectdojo-key"
}

# Single EC2 instance for DefectDojo
resource "aws_instance" "defectdojo" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.defectdojo_key.key_name

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile_name

  user_data_base64 = base64encode(replace(
    file("${path.module}/user_data.sh"),
    "PROJECT_NAME_PLACEHOLDER",
    var.project_name
  ))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-defectdojo"
    Type = "DefectDojo Server"
  })
}

# S3 bucket for DefectDojo file uploads
resource "aws_s3_bucket" "defectdojo_uploads" {
  bucket = "${var.project_name}-defectdojo-uploads-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Purpose = "DefectDojo file uploads"
  })
}

# Random suffix for S3 bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "defectdojo_uploads" {
  bucket = aws_s3_bucket.defectdojo_uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "defectdojo_uploads" {
  bucket = aws_s3_bucket.defectdojo_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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
