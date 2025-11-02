##########################################
# ROOT - variables.tf
##########################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "reverse-proxy"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
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
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}

variable "private_key_path" {
  description = "Path to private SSH key"
  type        = string
}

variable "app_source_path" {
  description = "Path to backend application files"
  type        = string
  default     = "./provisioners/app"
}

variable "ip_output_file" {
  description = "Output file for IPs"
  type        = string
  default     = "./all-ips.txt"
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "ReverseProxy"
  }
}