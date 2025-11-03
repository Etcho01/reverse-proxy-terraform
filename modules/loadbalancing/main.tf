##########################################
# LOAD BALANCING MODULE - main.tf
# Creates ALBs, Target Groups, Listeners, and Attachments
##########################################

# --- Public ALB ---
resource "aws_lb" "public_alb" {
  name               = "${var.project_name}-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_public_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-public-alb" 
  })
}

# --- Internal ALB ---
resource "aws_lb" "internal_alb" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_internal_sg_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-internal-alb" 
  })
}

# --- Target Group: Proxy ---
resource "aws_lb_target_group" "proxy_tg" {
  name     = "${var.project_name}-proxy-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-proxy-tg" 
  })
}

# --- Target Group: Backend ---
# CHANGED: Backend now listens on port 5000
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg"
  port     = 5000  # Changed from 80 to 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"  # Using dedicated health endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, { 
    Name = "${var.project_name}-backend-tg" 
  })
}

# --- Listener: Public ALB ---
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_tg.arn
  }
}

# --- Listener: Internal ALB ---
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# NOTE: Target group attachments moved to root main.tf to avoid circular dependency