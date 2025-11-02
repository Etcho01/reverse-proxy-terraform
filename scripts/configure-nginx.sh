#!/bin/bash

# Read BACKEND_DNS from Terraform interpolation
BACKEND_DNS="${BACKEND_DNS}"

cat <<EOF | sudo tee /etc/nginx/conf.d/reverse-proxy.conf
upstream backend {
    server $BACKEND_DNS;
}
...
EOF
sudo systemctl restart nginx
