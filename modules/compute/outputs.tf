##########################################
# COMPUTE MODULE - outputs.tf
##########################################

output "proxy_instance_ids" {
  description = "List of proxy EC2 instance IDs"
  value       = aws_instance.proxy[*].id
}

output "proxy_public_ips" {
  description = "List of proxy public IPs"
  value       = aws_instance.proxy[*].public_ip
}

output "proxy_private_ips" {
  description = "List of proxy private IPs"
  value       = aws_instance.proxy[*].private_ip
}

output "backend_instance_ids" {
  description = "List of backend EC2 instance IDs"
  value       = aws_instance.backend[*].id
}

output "backend_private_ips" {
  description = "List of backend private IPs"
  value       = aws_instance.backend[*].private_ip
}

output "ami_id" {
  description = "AMI ID used for instances"
  value       = data.aws_ami.amazon_linux.id
}