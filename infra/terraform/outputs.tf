# DefectDojo MVP Outputs

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

# DefectDojo Access Information
output "defectdojo_access_info" {
  description = "Information to access DefectDojo"
  value = {
    admin_username = "admin"
    admin_password = "DefectDojoMVP2024!"
    admin_email    = "admin@defectdojo.local"
    note           = "Access via EC2 public IPs on port 80. Check ECS service for instance IPs."
  }
}

# RDS Database
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

# Redis Cache (optional for MVP)
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

# ECS Cluster Information
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

# Access Information
output "access_instructions" {
  description = "How to access your DefectDojo MVP"
  value       = <<-EOT
    
    🚀 DefectDojo MVP Deployment Complete!
    
    📋 Next Steps:
    
    1. Build and push images:
       ./build-and-push.sh
    
    2. Find your EC2 instance public IPs:
       - Go to AWS Console → EC2 → Instances
       - Look for instances tagged: ${module.ecs.cluster_name}
    
    3. Access DefectDojo:
       - URL: http://<EC2-PUBLIC-IP>
       - Default login: admin/admin
       - Port: 80 (HTTP)
    
    💡 Tips:
    - Without ALB, you access directly via EC2 instance IPs
    - If one instance is down, try another instance IP
    - Check ECS service status in AWS Console
    
    🔧 Resources Created:
    - ECS Cluster: ${module.ecs.cluster_name}
    - Database: ${module.rds.endpoint}
    - ECR Repos: Django & Nginx
    - EC2 Spot instances: 2-3 instances
    
    💰 Estimated cost: ~$50/month
  EOT
}
