# ECR Module for DefectDojo (Simplified)

# ECR Repository for Django DefectDojo application
resource "aws_ecr_repository" "django" {
  name                 = "${var.project_name}/django"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # Simplified for MVP
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-django-ecr"
  })
}

# ECR Repository for Nginx proxy
resource "aws_ecr_repository" "nginx" {
  name                 = "${var.project_name}/nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # Simplified for MVP
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-nginx-ecr"
  })
}
