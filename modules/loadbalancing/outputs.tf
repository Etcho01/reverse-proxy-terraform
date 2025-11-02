##########################################
# LOAD BALANCING MODULE - outputs.tf
##########################################

output "public_alb_dns" {
  description = "DNS name of the public ALB"
  value       = aws_lb.public_alb.dns_name
}

output "public_alb_arn" {
  description = "ARN of the public ALB"
  value       = aws_lb.public_alb.arn
}

output "internal_alb_dns" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.internal_alb.dns_name
}

output "internal_alb_arn" {
  description = "ARN of the internal ALB"
  value       = aws_lb.internal_alb.arn
}

output "proxy_target_group_arn" {
  description = "ARN of the proxy target group"
  value       = aws_lb_target_group.proxy_tg.arn
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend_tg.arn
}