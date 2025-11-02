##########################################
# NETWORK MODULE - variables.tf
##########################################

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}