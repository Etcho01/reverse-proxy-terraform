sudo tee /etc/systemd/system/flask-app.service > /dev/null <<EOF
[Unit]
Description=Flask Backend Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
Environment="PYTHONUNBUFFERED=1"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"    # ← THIS LINE IS NEW!
ExecStart=/usr/bin/python3 $APP_DIR/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF