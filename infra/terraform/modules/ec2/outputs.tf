output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.defectdojo.id
}

output "instance_id" {
  description = "ID of the DefectDojo instance"
  value       = aws_instance.defectdojo.id
}

output "instance_public_ip" {
  description = "Public IP of the DefectDojo instance"
  value       = aws_instance.defectdojo.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the DefectDojo instance"
  value       = aws_instance.defectdojo.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the DefectDojo instance"
  value       = aws_instance.defectdojo.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${data.aws_key_pair.defectdojo_key.key_name}.pem ec2-user@${aws_instance.defectdojo.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for uploads"
  value       = aws_s3_bucket.defectdojo_uploads.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for DefectDojo uploads"
  value       = aws_s3_bucket.defectdojo_uploads.arn
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = data.aws_key_pair.defectdojo_key.key_name
}
