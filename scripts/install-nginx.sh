#!/bin/bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures

echo "Installing Nginx..."

# Update system packages
echo "Updating system packages..."
sudo yum update -y

# Install Nginx
echo "Installing Nginx from amazon-linux-extras..."
sudo amazon-linux-extras install -y nginx1

# Enable Nginx to start on boot
echo "Enabling Nginx service..."
sudo systemctl enable nginx

# Start Nginx
echo "Starting Nginx service..."
sudo systemctl start nginx

# Wait a moment for service to start
sleep 2

# Verify Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginx successfully installed and running"
    sudo systemctl status nginx --no-pager
else
    echo "✗ ERROR: Nginx failed to start"
    sudo systemctl status nginx --no-pager
    exit 1
fi

# Verify Nginx is listening on port 80
if sudo netstat -tuln | grep -q ":80 "; then
    echo "✓ Nginx is listening on port 80"
else
    echo "⚠ WARNING: Nginx is not listening on port 80"
fi