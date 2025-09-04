# ECS Module Variables for DefectDojo MVP

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS instances"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ECS instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "django_image_uri" {
  description = "ECR URI for Django image"
  type        = string
}

variable "nginx_image_uri" {
  description = "ECR URI for Nginx image"
  type        = string
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis connection URL (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "execution_role_arn" {
  description = "ARN of ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

variable "django_secret_key" {
  description = "Django secret key for cryptographic operations"
  type        = string
  sensitive   = true
  default     = "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq-MVP-DEFAULT"
}

variable "django_aes_key" {
  description = "Django AES key for credential encryption"
  type        = string
  sensitive   = true
  default     = "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
