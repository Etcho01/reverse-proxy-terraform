#!/bin/bash

APP_DIR=${APP_DIR:-"/tmp/app"}  # fallback

sudo yum update -y
sudo yum install python3 python3-pip -y
cd $APP_DIR
sudo pip3 install -r requirements.txt || true
sudo nohup python3 app.py &
