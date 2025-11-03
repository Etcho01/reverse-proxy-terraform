#!/bin/bash
set -e

echo "=========================================="
echo "502 Bad Gateway Debugging Script"
echo "=========================================="
echo ""

# Get terraform outputs (without jq)
echo "📋 Getting infrastructure info..."
PROXY_IP=$(terraform output -raw proxy_public_ips | head -1 | tr -d '[]" ' | cut -d',' -f1)
BACKEND_IP=$(terraform output -raw backend_private_ips | head -1 | tr -d '[]" ' | cut -d',' -f1)
INTERNAL_ALB=$(terraform output -raw internal_alb_dns)
PUBLIC_ALB=$(terraform output -raw public_alb_url)

echo "  Proxy IP: $PROXY_IP"
echo "  Backend IP: $BACKEND_IP"
echo "  Internal ALB: $INTERNAL_ALB"
echo "  Public ALB: $PUBLIC_ALB"
echo ""

# Test from proxy
echo "🔍 Testing connectivity from proxy to internal ALB..."
echo "  Running: curl http://$INTERNAL_ALB from proxy..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$PROXY_IP "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://$INTERNAL_ALB --connect-timeout 5" 2>&1 || echo "  ✗ Cannot reach internal ALB from proxy"
echo ""

# Check nginx config
echo "🔧 Checking Nginx configuration on proxy..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no ec2-user@$PROXY_IP "sudo cat /etc/nginx/conf.d/reverse-proxy.conf 2>/dev/null" || echo "  ✗ Nginx config not found"
echo ""

# Check nginx status
echo "📊 Checking Nginx status on proxy..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no ec2-user@$PROXY_IP "sudo systemctl status nginx --no-pager -l" || echo "  ✗ Nginx status check failed"
echo ""

# Check nginx errors
echo "📜 Recent Nginx errors on proxy (last 20 lines)..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no ec2-user@$PROXY_IP "sudo tail -n 20 /var/log/nginx/error.log 2>/dev/null" || echo "  No error log or empty"
echo ""

# Test backend directly
echo "🔍 Testing Flask app on backend via SSH tunnel..."
echo "  Running: curl http://localhost:5000 from backend..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no \
  -J ec2-user@$PROXY_IP \
  ec2-user@$BACKEND_IP \
  "curl -s http://localhost:5000 2>&1" || echo "  ✗ Cannot reach Flask app on backend"
echo ""

# Check Flask service
echo "📊 Checking Flask service status on backend..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no \
  -J ec2-user@$PROXY_IP \
  ec2-user@$BACKEND_IP \
  "sudo systemctl status flask-app --no-pager -l" || echo "  ✗ Flask service check failed"
echo ""

# Check if Flask is listening
echo "🔌 Checking if Flask is listening on port 5000..."
ssh -i ~/.ssh/wsl-terraform-key.pem -o StrictHostKeyChecking=no \
  -J ec2-user@$PROXY_IP \
  ec2-user@$BACKEND_IP \
  "sudo netstat -tuln | grep ':5000'" || echo "  ✗ Flask is NOT listening on port 5000"
echo ""

echo "=========================================="
echo "🎯 Diagnosis Complete!"
echo "=========================================="