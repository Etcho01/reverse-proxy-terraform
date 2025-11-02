##########################################
# SECURITY MODULE - outputs.tf
##########################################

output "alb_public_sg_id" {
  description = "Security group ID for public ALB"
  value       = aws_security_group.alb_public_sg.id
}

output "alb_internal_sg_id" {
  description = "Security group ID for internal ALB"
  value       = aws_security_group.alb_internal_sg.id
}

output "proxy_sg_id" {
  description = "Security group ID for proxy instances"
  value       = aws_security_group.proxy_sg.id
}

output "backend_sg_id" {
  description = "Security group ID for backend instances"
  value       = aws_security_group.backend_sg.id
}