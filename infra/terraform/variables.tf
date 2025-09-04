# DefectDojo MVP Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "defectdojo-mvp"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Database Configuration
variable "db_password" {
  description = "Password for RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ECS Configuration
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

# Network Configuration (simplified)
variable "web_allowed_cidrs" {
  description = "CIDR blocks allowed to access the web application"
  type        = list(string)
  default     = ["0.0.0.0/0"] # MVP: Allow all (change for production)
}

# Redis Configuration (optional for MVP)
variable "enable_redis" {
  description = "Enable Redis for caching and Celery"
  type        = bool
  default     = false # Disabled for MVP simplicity
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}
