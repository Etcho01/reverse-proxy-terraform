##########################################
# terraform.tfvars
# ACTUAL VALUES FILE
##########################################

region       = "eu-west-1"
project_name = "reverse-proxy"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.3.0/24"]

# Compute Configuration
proxy_count   = 2
backend_count = 2
instance_type = "t3.micro"

# SSH Configuration - UPDATE THESE WITH YOUR VALUES!
key_name         = "wsl-terraform-key"
private_key_path = "~/.ssh/wsl-terraform-key.pem"

# Application Paths
app_source_path = "./provisioners/app"
ip_output_file  = "./all-ips.txt"

# Tags
common_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "ReverseProxy"
  Owner       = "Mohamed Hesham"
}