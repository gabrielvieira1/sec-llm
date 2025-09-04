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

# Phase Status Updated
output "phase2_status" {
  description = "Phase 2 deployment status"
  value = {
    phase        = "Phase 2: Security + ECR + Redis + RDS"
    status       = "Complete"
    next_step    = "Uncomment ECS module in main.tf and run terraform apply for Phase 3"
    ecr_ready    = "Ready for Docker image builds"
    rds_ready    = "PostgreSQL database ready"
    redis_status = var.enable_redis ? "Enabled" : "Disabled (using default for MVP)"
  }
}

# Commented outputs for future phases
# Uncomment when enabling ECS module (Phase 3)

# # ECS Cluster (Phase 3)
# output "ecs_cluster_name" {
#   description = "ECS cluster name"
#   value       = module.ecs.cluster_name
# }

# output "ecs_service_name" {
#   description = "ECS service name"
#   value       = module.ecs.service_name
# }
