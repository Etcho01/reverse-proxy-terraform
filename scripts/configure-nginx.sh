#!/bin/bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Read BACKEND_DNS from environment variable (set by Terraform)
if [ -z "${BACKEND_DNS:-}" ]; then
    echo "ERROR: BACKEND_DNS environment variable is not set"
    exit 1
fi

echo "Configuring Nginx reverse proxy to backend: $BACKEND_DNS"

# Create Nginx reverse proxy configuration
cat <<EOF | sudo tee /etc/nginx/conf.d/reverse-proxy.conf
upstream backend {
    server $BACKEND_DNS:80;
    keepalive 32;
}

server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Connection "";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Remove default Nginx configuration to avoid conflicts
sudo rm -f /etc/nginx/conf.d/default.conf

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Verify Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginx successfully configured and running"
    echo "✓ Backend DNS: $BACKEND_DNS"
else
    echo "✗ ERROR: Nginx failed to start"
    sudo systemctl status nginx
    exit 1
fi