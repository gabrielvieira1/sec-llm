# DefectDojo MVP Outputs - Simplified EC2 Architecture

# EC2 Instance Information
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the DefectDojo instance"
  value       = module.ec2.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the DefectDojo instance"
  value       = module.ec2.instance_public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = module.ec2.ssh_connection_command
}

# RDS Information
output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
}

output "database_port" {
  description = "RDS PostgreSQL port"
  value       = module.rds.port
}

# S3 Information
output "s3_bucket_name" {
  description = "S3 bucket name for DefectDojo uploads"
  value       = module.ec2.s3_bucket_name
}

# Security Groups
output "security_groups" {
  description = "Created security group IDs"
  value = {
    defectdojo_sg_id = module.networking.defectdojo_security_group_id
    rds_sg_id        = module.networking.rds_security_group_id
  }
}

# Application URLs
output "application_urls" {
  description = "DefectDojo application URLs"
  value = {
    http  = "http://${module.ec2.instance_public_ip}"
    https = "https://${module.ec2.instance_public_ip}"
    app   = "http://${module.ec2.instance_public_ip}:8080"
  }
}

# Next Steps
output "next_steps" {
  description = "Next steps to access DefectDojo"
  value       = <<-EOT
    1. Wait 5-10 minutes for DefectDojo to be fully installed
    2. Access DefectDojo at: http://${module.ec2.instance_public_ip}:8080
    3. SSH to instance: ${module.ec2.ssh_connection_command}
    4. Check logs: ssh ubuntu@${module.ec2.instance_public_ip} 'tail -f /var/log/defectdojo-install.log'
    5. Default login will be created during first boot
  EOT
}
