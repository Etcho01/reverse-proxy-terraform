##########################################
# COMPUTE MODULE - main.tf
# Creates EC2 instances with provisioners
##########################################

# --- Data Source: Amazon Linux 2 AMI ---
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# =====================================================
# PUBLIC PROXY INSTANCES (NGINX REVERSE PROXIES)
# =====================================================
resource "aws_instance" "proxy" {
  count                  = var.proxy_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [var.proxy_sg_id]
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-proxy-${count.index + 1}"
    Role = "proxy"
  })

  # --- Connection for SSH Provisioners ---
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "5m"
  }

  # --- Install Nginx (script uploaded and executed remotely) ---
  provisioner "remote-exec" {
    script = "${path.module}/../../scripts/install-nginx.sh"
  }

  # --- Upload and Configure Nginx Reverse Proxy ---
  provisioner "file" {
    source      = "${path.module}/../../scripts/configure-nginx.sh"
    destination = "/tmp/configure-nginx.sh"
  }

  provisioner "remote-exec" {
    inline = [
      # Export BACKEND_DNS and run configuration in one command to keep env available
      "chmod +x /tmp/configure-nginx.sh && BACKEND_DNS='${var.internal_alb_dns}' bash /tmp/configure-nginx.sh"
    ]
  }

  # --- Output Proxy Public IP locally for records ---
  provisioner "local-exec" {
    command = "echo 'proxy-ip${count.index + 1} ${self.public_ip}' >> ${var.ip_output_file}"
  }
}

# =====================================================
# BACKEND INSTANCES (FLASK APP)
# =====================================================
resource "aws_instance" "backend" {
  count                  = var.backend_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.backend_sg_id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backend-${count.index + 1}"
    Role = "backend"
  })

  # --- Connection (via Bastion/Proxy Host) ---
  connection {
    type                = "ssh"
    user                = "ec2-user"
    private_key         = file(var.private_key_path)
    host                = self.private_ip
    bastion_host        = aws_instance.proxy[0].public_ip
    bastion_user        = "ec2-user"
    bastion_private_key = file(var.private_key_path)
    timeout             = "5m"
  }

  # --- Upload Flask App Code to Remote Instance ---
  provisioner "file" {
    source      = var.app_source_path
    destination = "/tmp/app"
  }

  # --- Upload Flask Install Script ---
  provisioner "file" {
    source      = "${path.module}/../../scripts/install-flask.sh"
    destination = "/tmp/install-flask.sh"
  }

  # --- Execute Install Script with APP_DIR variable in one inline ---
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-flask.sh && APP_DIR=/tmp/app bash /tmp/install-flask.sh"
    ]
  }

  # --- Output Backend Private IP locally for records ---
  provisioner "local-exec" {
    command = "echo 'backend-ip${count.index + 1} ${self.private_ip}' >> ${var.ip_output_file}"
  }

  depends_on = [aws_instance.proxy]
}
