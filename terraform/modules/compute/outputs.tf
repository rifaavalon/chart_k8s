output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.app[*].private_ip
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = aws_instance.app[*].public_ip
}

output "security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance.id
}
