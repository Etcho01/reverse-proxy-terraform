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

# --- Proxy EC2 Instances (Public Subnets) ---
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

  # --- Connection for Provisioners ---
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "5m"
  }

  # --- Remote Exec: Install Nginx ---
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }

  # --- Remote Exec: Configure Nginx as Reverse Proxy ---
  provisioner "remote-exec" {
    inline = [
      "sudo tee /etc/nginx/conf.d/reverse-proxy.conf > /dev/null <<'EOF'",
      "upstream backend {",
      "    server ${var.internal_alb_dns};",
      "}",
      "",
      "server {",
      "    listen 80;",
      "    location / {",
      "        proxy_pass http://backend;",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "    }",
      "}",
      "EOF",
      "sudo systemctl restart nginx"
    ]
  }

  # --- Local Exec: Print IP to File ---
  provisioner "local-exec" {
    command = "echo 'proxy-ip${count.index + 1} ${self.public_ip}' >> ${var.ip_output_file}"
  }

  depends_on = [var.internal_alb_dns]
}

# --- Backend EC2 Instances (Private Subnets) ---
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

  # --- Connection via Bastion (Proxy) ---
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

  # --- File Provisioner: Copy Application Files ---
  provisioner "file" {
    source      = var.app_source_path
    destination = "/tmp/app"
  }

  # --- Remote Exec: Install Python & Flask ---
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install python3 python3-pip -y",
      "cd /tmp/app",
      "sudo pip3 install -r requirements.txt || true",
      "sudo python3 app.py &"
    ]
  }

  # --- Local Exec: Print Private IP to File ---
  provisioner "local-exec" {
    command = "echo 'backend-ip${count.index + 1} ${self.private_ip}' >> ${var.ip_output_file}"
  }

  depends_on = [aws_instance.proxy]
}