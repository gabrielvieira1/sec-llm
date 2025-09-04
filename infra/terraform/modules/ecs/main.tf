# ECS Module for DefectDojo MVP - Simplified Version
# This version focuses on simplicity and cost optimization

# Get latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

data "aws_region" "current" {}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Disabled for MVP to save costs
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-cluster"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "defectdojo" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 3 # Short retention for MVP

  tags = var.tags
}

# IAM role for EC2 instances to join ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach ECS instance policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Allow access to SSM parameters
resource "aws_iam_role_policy" "ecs_ssm_policy" {
  name = "${var.project_name}-ecs-ssm-policy"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name

  tags = var.tags
}

# Launch Template for EC2 Spot Instances
resource "aws_launch_template" "ecs_spot" {
  name_prefix   = "${var.project_name}-ecs-spot-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  # IAM instance profile for ECS
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Spot instance configuration
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.05" # Max price for t3.small spot
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-ecs-instance"
    })
  }

  tags = var.tags
}

# Auto Scaling Group for ECS Instances
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.project_name}-ecs-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_spot.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Store database URL in SSM Parameter Store
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.project_name}/database_url"
  type  = "SecureString"
  value = var.database_url

  tags = var.tags
}

# Store Redis URL in SSM Parameter Store (optional)
resource "aws_ssm_parameter" "redis_url" {
  count = var.redis_url != "" ? 1 : 0
  name  = "/${var.project_name}/redis_url"
  type  = "SecureString"
  value = var.redis_url

  tags = var.tags
}

# ECS Task Definition - Simplified for MVP
resource "aws_ecs_task_definition" "defectdojo" {
  family                   = "${var.project_name}-defectdojo"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  # Simplified container definition focusing on core functionality
  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = var.nginx_image_uri
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 80 # Map to port 80 on host for easy access
          protocol      = "tcp"
        }
      ]
      essential = true
      links     = ["django"]
      environment = [
        {
          name  = "DD_UWSGI_HOST"
          value = "django"
        },
        {
          name  = "DD_UWSGI_PORT"
          value = "3031"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.defectdojo.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "nginx"
        }
      }
      volumesFrom = [
        {
          sourceContainer = "django"
          readOnly        = false
        }
      ]
    },
    {
      name  = "django"
      image = var.django_image_uri
      portMappings = [
        {
          containerPort = 3031
          protocol      = "tcp"
        }
      ]
      essential = true
      environment = [
        {
          name  = "DD_DEBUG"
          value = "False"
        },
        {
          name  = "DD_ALLOWED_HOSTS"
          value = "*" # Allow all hosts for MVP
        },
        {
          name  = "DD_SECRET_KEY"
          value = "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq" # Change for production
        },
        {
          name  = "DD_CREDENTIAL_AES_256_KEY"
          value = "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw" # Change for production
        },
        # Use SQLite for MVP simplicity - or database if available
        {
          name  = "DD_DATABASE_ENGINE"
          value = "django.db.backends.postgresql"
        }
      ]
      secrets = [
        {
          name      = "DD_DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        }
        # Only add Redis URL if available
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.defectdojo.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "django"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-task-definition"
  })
}

# ECS Service - Simplified
resource "aws_ecs_service" "defectdojo" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.defectdojo.arn
  desired_count   = 1 # Start with just 1 for MVP

  # Spread tasks across different instances
  placement_constraints {
    type = "distinctInstance"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-service"
  })
}
