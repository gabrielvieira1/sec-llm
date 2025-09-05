output "instance_id" {
  description = "ID of the DefectDojo EC2 instance"
  value       = aws_instance.defectdojo.id
}

output "instance_public_ip" {
  description = "Public IP address of the DefectDojo EC2 instance"
  value       = aws_instance.defectdojo.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the DefectDojo EC2 instance"
  value       = aws_instance.defectdojo.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the DefectDojo EC2 instance"
  value       = aws_instance.defectdojo.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${data.aws_key_pair.defectdojo_key.key_name}.pem ubuntu@${aws_instance.defectdojo.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for DefectDojo uploads"
  value       = aws_s3_bucket.defectdojo_uploads.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for DefectDojo uploads"
  value       = aws_s3_bucket.defectdojo_uploads.arn
}

output "key_pair_name" {
  description = "Name of the key pair used for SSH access"
  value       = data.aws_key_pair.defectdojo_key.key_name
}
