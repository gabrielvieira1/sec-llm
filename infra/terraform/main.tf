# Main Terraform Configuration for DefectDojo MVP
# Simplified setup using default VPC and EC2 Spot instances

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

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# Security Groups Module (simplified)
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  vpc_id            = data.aws_vpc.default.id
  web_allowed_cidrs = var.web_allowed_cidrs
  tags              = local.common_tags
}

# ECR Module - Container Registry
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  tags         = local.common_tags
}

# RDS Module - PostgreSQL Database (simplified)
# Comentado para Fase 1 - vamos testar incrementalmente
# module "rds" {
#   source = "./modules/rds"

#   project_name       = var.project_name
#   vpc_id             = data.aws_vpc.default.id
#   subnet_ids         = data.aws_subnets.default.ids
#   security_group_ids = [module.security.rds_sg_id]
#   instance_class     = var.db_instance_class
#   db_password        = var.db_password
#   tags               = local.common_tags
# }

# Redis Module - ElastiCache (optional for MVP)
module "redis" {
  count  = var.enable_redis ? 1 : 0
  source = "./modules/redis"

  project_name       = var.project_name
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [module.security.redis_sg_id]
  node_type          = var.redis_node_type
  tags               = local.common_tags
}

# ECS Module - Container Service with EC2 Spot instances
# Comentado para Fase 1 - vamos testar incrementalmente
# module "ecs" {
#   source = "./modules/ecs"

#   project_name       = var.project_name
#   vpc_id             = data.aws_vpc.default.id
#   subnet_ids         = data.aws_subnets.default.ids
#   security_group_ids = [module.security.ecs_sg_id]

#   # EC2 Configuration
#   instance_type    = var.instance_type
#   min_size         = var.min_size
#   max_size         = var.max_size
#   desired_capacity = var.desired_capacity

#   # ECR Repository URLs
#   django_image_uri = module.ecr.django_repository_url
#   nginx_image_uri  = module.ecr.nginx_repository_url

#   # Database Configuration
#   database_url = module.rds.database_url
#   redis_url    = var.enable_redis ? module.redis[0].redis_url : "redis://localhost:6379/0" # Fallback for MVP

#   # IAM Roles
#   execution_role_arn = module.security.ecs_execution_role_arn
#   task_role_arn      = module.security.ecs_task_role_arn

#   tags = local.common_tags
# }


