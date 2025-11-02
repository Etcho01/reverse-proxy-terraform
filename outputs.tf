##########################################
# ROOT - outputs.tf
##########################################

output "public_alb_url" {
  description = "Public ALB DNS (main entry point)"
  value       = "http://${module.loadbalancing.public_alb_dns}"
}

output "internal_alb_dns" {
  description = "Internal ALB DNS"
  value       = module.loadbalancing.internal_alb_dns
}

output "proxy_public_ips" {
  description = "Proxy instance public IPs"
  value       = module.compute.proxy_public_ips
}

output "proxy_private_ips" {
  description = "Proxy instance private IPs"
  value       = module.compute.proxy_private_ips
}

output "backend_private_ips" {
  description = "Backend instance private IPs"
  value       = module.compute.backend_private_ips
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "ami_id" {
  description = "AMI ID used for EC2 instances"
  value       = module.compute.ami_id
}

output "proxy_instance_ids" {
  description = "Proxy EC2 instance IDs"
  value       = module.compute.proxy_instance_ids
}

output "backend_instance_ids" {
  description = "Backend EC2 instance IDs"
  value       = module.compute.backend_instance_ids
}

output "public_alb_arn" {
  description = "Public ALB ARN"
  value       = module.loadbalancing.public_alb_arn
}

output "internal_alb_arn" {
  description = "Internal ALB ARN"
  value       = module.loadbalancing.internal_alb_arn
}