#!/bin/bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Get APP_DIR from environment variable with fallback
APP_DIR=${APP_DIR:-"/tmp/app"}

echo "Installing Flask application from: $APP_DIR"

# Verify APP_DIR exists
if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: APP_DIR $APP_DIR does not exist"
    exit 1
fi

# Update system
echo "Updating system packages..."
sudo yum update -y

# Install Python and pip
echo "Installing Python3 and pip..."
sudo yum install -y python3 python3-pip

# Install Python dependencies
echo "Installing Flask dependencies..."
cd "$APP_DIR"
if [ -f "requirements.txt" ]; then
    sudo pip3 install -r requirements.txt
else
    echo "ERROR: requirements.txt not found in $APP_DIR"
    exit 1
fi

# Create systemd service for Flask app
echo "Creating systemd service..."
sudo tee /etc/systemd/system/flask-app.service > /dev/null <<EOF
[Unit]
Description=Flask Backend Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
Environment="PYTHONUNBUFFERED=1"
ExecStart=/usr/bin/python3 $APP_DIR/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start Flask service
echo "Starting Flask application..."
sudo systemctl enable flask-app.service
sudo systemctl start flask-app.service

# Wait a moment for service to start
sleep 3

# Verify service is running
if sudo systemctl is-active --quiet flask-app; then
    echo "✓ Flask application successfully installed and running"
    echo "✓ Service status:"
    sudo systemctl status flask-app --no-pager -l
else
    echo "✗ ERROR: Flask application failed to start"
    sudo systemctl status flask-app --no-pager -l
    sudo journalctl -u flask-app -n 50 --no-pager
    exit 1
fi

# Check if app is listening on port 80
if sudo netstat -tuln | grep -q ":80 "; then
    echo "✓ Flask app is listening on port 80"
else
    echo "⚠ WARNING: Flask app is not listening on port 80"
fi