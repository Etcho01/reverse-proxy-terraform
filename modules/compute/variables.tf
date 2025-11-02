##########################################
# COMPUTE MODULE - variables.tf
##########################################

variable "project_name" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "proxy_count" {
  description = "Number of proxy instances"
  type        = number
  default     = 2
}

variable "backend_count" {
  description = "Number of backend instances"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "private_key_path" {
  description = "Path to private SSH key for provisioners"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "proxy_sg_id" {
  description = "Security group ID for proxy instances"
  type        = string
}

variable "backend_sg_id" {
  description = "Security group ID for backend instances"
  type        = string
}

variable "internal_alb_dns" {
  description = "DNS name of internal ALB (for nginx config)"
  type        = string
}

variable "app_source_path" {
  description = "Local path to backend application files"
  type        = string
  default     = "./provisioners/app"
}

variable "ip_output_file" {
  description = "File path for IP output (local-exec)"
  type        = string
  default     = "./all-ips.txt"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}