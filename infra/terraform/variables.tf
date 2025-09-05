# DefectDojo MVP Variables - Simplified EC2 Architecture

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sec-llm-infra-defectdojo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_password" {
  description = "Password for RDS PostgreSQL database"
  type        = string
  sensitive   = true
  default     = "MySecurePassword123!"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type for DefectDojo server"
  type        = string
  default     = "t3.small"
}
