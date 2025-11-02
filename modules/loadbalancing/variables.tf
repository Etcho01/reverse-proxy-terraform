##########################################
# LOAD BALANCING MODULE - variables.tf
##########################################

variable "project_name" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources are deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for public ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for internal ALB"
  type        = list(string)
}

variable "alb_public_sg_id" {
  description = "Security group ID for public ALB"
  type        = string
}

variable "alb_internal_sg_id" {
  description = "Security group ID for internal ALB"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}