output "vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "List of subnet IDs in the default VPC"
  value       = data.aws_subnets.default.ids
}

output "defectdojo_security_group_id" {
  description = "ID of the DefectDojo EC2 security group"
  value       = aws_security_group.defectdojo.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
