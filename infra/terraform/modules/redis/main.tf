# Redis Module for DefectDojo MVP - Simplified

# Create cache subnet group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-cache-subnet-group"
  })
}

# ElastiCache Redis (simplified for MVP)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cache for ${var.project_name}"

  # Node configuration
  node_type = var.node_type
  port      = 6379

  # Cluster configuration (simplified)
  num_cache_clusters = 1

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = var.security_group_ids

  # Simplified settings for MVP
  engine_version       = "7.0"
  parameter_group_name = "default.redis7"

  # Backup settings (minimal for MVP)
  snapshot_retention_limit = 1
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  # Security settings (simplified for MVP)
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  auth_token                 = null

  # Automatic failover disabled for single node
  automatic_failover_enabled = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-redis"
  })
}
