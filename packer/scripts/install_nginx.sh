#!/usr/bin/env bash
set -euxo pipefail

sudo apt-get update
sudo apt-get install -y nginx curl

sudo systemctl enable nginx
sudo systemctl start nginx

# validation
sudo systemctl is-active nginx
curl -I http://localhost | grep "200 OK"