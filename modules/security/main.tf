##########################################
# SECURITY MODULE - main.tf
# Creates all security groups for the infrastructure
##########################################

# Public ALB Security Group
resource "aws_security_group" "alb_public_sg" {
  name        = "${var.project_name}-alb-public-sg"
  description = "Allow HTTP traffic to public ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-alb-public-sg" 
  })
}

# Internal ALB Security Group
resource "aws_security_group" "alb_internal_sg" {
  name        = "${var.project_name}-alb-internal-sg"
  description = "Allow HTTP from proxies to internal ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-alb-internal-sg" 
  })
}

# Proxy EC2 Security Group
resource "aws_security_group" "proxy_sg" {
  name        = "${var.project_name}-proxy-sg"
  description = "Allow ALB to Proxy and SSH access"
  vpc_id      = var.vpc_id

  # Allow SSH for provisioners
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-proxy-sg" 
  })
}

# Backend EC2 Security Group
resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Allow internal ALB to backend and SSH via bastion"
  vpc_id      = var.vpc_id

  # Allow SSH from proxy instances (they act as bastion)
  ingress {
    description = "SSH from proxies"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.proxy_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-backend-sg" 
  })
}

# Security Group Rules (created after all SGs exist to avoid circular dependencies)

# Allow Public ALB -> Proxy (port 80)
resource "aws_security_group_rule" "alb_public_to_proxy" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.proxy_sg.id
  source_security_group_id = aws_security_group.alb_public_sg.id
  description              = "Allow HTTP from public ALB"
}

# Allow Proxy -> Internal ALB (port 80)
resource "aws_security_group_rule" "proxy_to_internal_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_internal_sg.id
  source_security_group_id = aws_security_group.proxy_sg.id
  description              = "Allow HTTP from proxies"
}

# CHANGED: Allow Internal ALB -> Backend (port 5000 instead of 80)
resource "aws_security_group_rule" "internal_alb_to_backend" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.alb_internal_sg.id
  description              = "Allow HTTP from internal ALB on port 5000"
}