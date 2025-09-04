# ECR Module Outputs

output "django_repository_url" {
  description = "URL of the Django ECR repository"
  value       = aws_ecr_repository.django.repository_url
}

output "nginx_repository_url" {
  description = "URL of the Nginx ECR repository"
  value       = aws_ecr_repository.nginx.repository_url
}
