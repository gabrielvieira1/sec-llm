# RDS Module for DefectDojo MVP - Simplified

# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# RDS PostgreSQL Instance (simplified for MVP)
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Database Configuration
  engine         = "postgres"
  engine_version = "16.10" # Latest available PostgreSQL 16.x, compatible with DefectDojo
  instance_class = var.instance_class

  # Database Details
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false # Simplified for MVP

  # Database Settings
  db_name  = "defectdojo"
  username = "defectdojo"
  password = var.db_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Backup Configuration (DISABLED for MVP)
  backup_retention_period = 0    # No backups for MVP
  backup_window           = null # Not needed when backups disabled
  maintenance_window      = "sun:04:00-sun:05:00"

  # Skip final snapshot for MVP (change for production)
  skip_final_snapshot = true

  # Disable deletion protection for MVP
  deletion_protection = false

  # Performance and Monitoring (simplified)
  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgres"
  })
}
