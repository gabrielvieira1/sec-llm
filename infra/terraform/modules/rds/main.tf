# RDS Module for DefectDojo MVP - Replicating exact working configuration

# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# RDS PostgreSQL Instance (exact configuration that worked locally)
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Database Configuration
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class

  # Database Details
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false

  # Database Settings (exact same as working local setup)
  db_name  = "defectdojo"
  username = "defectdojo"
  password = var.db_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = true

  # Backup Configuration (DISABLED for MVP - same as local)
  backup_retention_period = 0
  backup_window           = null
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  deletion_protection = false

  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgres"
  })
}
