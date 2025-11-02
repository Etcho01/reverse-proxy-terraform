##########################################
# SECURITY MODULE - variables.tf
##########################################

variable "project_name" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}