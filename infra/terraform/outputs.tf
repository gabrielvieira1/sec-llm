# DefectDojo MVP Outputs - Phase 1: Security + ECR + Redis (optional)

# ECR Repository URLs
output "django_repository_url" {
  description = "ECR repository URL for Django image"
  value       = module.ecr.django_repository_url
}

output "nginx_repository_url" {
  description = "ECR repository URL for Nginx image"
  value       = module.ecr.nginx_repository_url
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    django = module.ecr.django_repository_url
    nginx  = module.ecr.nginx_repository_url
  }
}

# Security Groups
output "security_groups" {
  description = "Created security group IDs"
  value = {
    ecs_sg_id = module.security.ecs_sg_id
    rds_sg_id = module.security.rds_sg_id
  }
}

# IAM Roles
output "iam_roles" {
  description = "Created IAM role ARNs"
  value = {
    ecs_execution_role = module.security.ecs_execution_role_arn
    ecs_task_role      = module.security.ecs_task_role_arn
  }
}

# Redis Cache (Phase 1 - optional)
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = var.enable_redis ? module.redis[0].endpoint : "Redis not enabled for MVP"
  sensitive   = false
}

output "redis_url" {
  description = "Complete Redis URL for DefectDojo"
  value       = var.enable_redis ? module.redis[0].redis_url : "Redis not enabled for MVP"
  sensitive   = false
}

# RDS Database (Phase 2 - enabled)
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "database_url" {
  description = "Complete database URL for DefectDojo"
  value       = module.rds.database_url
  sensitive   = true
}

# Phase Status Updated for Final Phase
output "phase3_status" {
  description = "Phase 3 deployment status"
  value = {
    phase        = "Phase 3: Complete MVP - Security + ECR + RDS + ECS"
    status       = "Complete"
    next_step    = "Build and deploy DefectDojo application using app-deploy workflow"
    ecr_ready    = "Ready for Docker image builds"
    rds_ready    = "PostgreSQL database ready"
    ecs_ready    = "EC2 Spot instances and ECS service ready"
    redis_status = var.enable_redis ? "Enabled" : "Disabled (using default for MVP)"
  }
}

# ECS Cluster Information (Phase 3 - enabled)
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

# All phases complete - no commented outputs needed
