#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "Installing Hyper-V integration services..."
sudo apt-get update -y
sudo apt-get install -y linux-cloud-tools-virtual linux-tools-virtual

echo "Updating system and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

# Установка GitLab CE (Omnibus)
echo "Downloading and installing GitLab CE..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# Пытаемся определить текущий IP-адрес для установки GitLab
IP_ADDR=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
if [ -z "$IP_ADDR" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
fi

echo "Installing GitLab CE with EXTERNAL_URL=http://$IP_ADDR"
sudo EXTERNAL_URL="http://$IP_ADDR" apt-get install -y gitlab-ce

# Ждем завершения базовой настройки
echo "GitLab base installation finished. Access at http://$IP_ADDR"
