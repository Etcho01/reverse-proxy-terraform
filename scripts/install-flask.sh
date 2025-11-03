#!/bin/bash
set -euo pipefail

# APP_DIR must be passed in the environment (fallback /tmp/app)
APP_DIR="${APP_DIR:-/tmp/app}"

echo "Starting Flask install script. APP_DIR=${APP_DIR}"

# Install Python + pip if missing
if ! command -v python3 >/dev/null 2>&1; then
  echo "Installing python3 and pip..."
  sudo yum update -y
  sudo yum install -y python3 python3-pip
else
  echo "python3 already present"
fi

# Create a venv to isolate dependencies (optional but recommended)
VENV="/opt/flaskenv"
if [ ! -d "${VENV}" ]; then
  echo "Creating virtualenv at ${VENV}..."
  sudo python3 -m venv "${VENV}"
  sudo "${VENV}/bin/pip" install --upgrade pip
fi

# Install app requirements if requirements.txt exists in APP_DIR
if [ -f "${APP_DIR}/requirements.txt" ]; then
  echo "Installing Python requirements from ${APP_DIR}/requirements.txt"
  sudo "${VENV}/bin/pip" install --no-cache-dir -r "${APP_DIR}/requirements.txt" || true
else
  echo "No requirements.txt found at ${APP_DIR}, skipping pip install"
fi

# Create systemd service (expand APP_DIR here: safe because APP_DIR is a shell var)
sudo tee /etc/systemd/system/flask-app.service > /dev/null <<EOF
[Unit]
Description=Flask Backend Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=${APP_DIR}
Environment=PYTHONUNBUFFERED=1
Environment=PATH=${VENV}/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=${VENV}/bin/python3 ${APP_DIR}/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start
sudo systemctl daemon-reload
sudo systemctl enable flask-app
sudo systemctl restart flask-app

# Verify service is running
if sudo systemctl is-active --quiet flask-app; then
  echo "✓ Flask service started"
else
  echo "✗ Flask failed to start — showing logs"
  sudo journalctl -u flask-app -n 50 --no-pager
  exit 1
fi
