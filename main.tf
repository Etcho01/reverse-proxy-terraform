##########################################
# ROOT - main.tf (FIXED)
# Orchestrates all modules
##########################################

# --- Network Module ---
module "network" {
  source = "./modules/network"

  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  common_tags          = var.common_tags
}

# --- Security Module ---
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  common_tags  = var.common_tags
}

# --- Load Balancing Module ---
module "loadbalancing" {
  source = "./modules/loadbalancing"

  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  alb_public_sg_id   = module.security.alb_public_sg_id
  alb_internal_sg_id = module.security.alb_internal_sg_id
  common_tags        = var.common_tags
}

# --- Compute Module ---
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  proxy_count        = var.proxy_count
  backend_count      = var.backend_count
  instance_type      = var.instance_type
  key_name           = var.key_name
  private_key_path   = var.private_key_path
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  proxy_sg_id        = module.security.proxy_sg_id
  backend_sg_id      = module.security.backend_sg_id
  internal_alb_dns   = module.loadbalancing.internal_alb_dns
  app_source_path    = var.app_source_path
  ip_output_file     = var.ip_output_file
  common_tags        = var.common_tags
}

# --- Target Group Attachments (Root Level) ---
resource "aws_lb_target_group_attachment" "proxy_attachment" {
  count            = var.proxy_count
  target_group_arn = module.loadbalancing.proxy_target_group_arn
  target_id        = module.compute.proxy_instance_ids[count.index]
  port             = 80
}

# CHANGED: Backend now runs on port 5000
resource "aws_lb_target_group_attachment" "backend_attachment" {
  count            = var.backend_count
  target_group_arn = module.loadbalancing.backend_target_group_arn
  target_id        = module.compute.backend_instance_ids[count.index]
  port             = 5000 # Changed from 80 to 5000
}