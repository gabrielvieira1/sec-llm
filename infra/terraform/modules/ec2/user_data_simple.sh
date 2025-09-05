#!/bin/bash

# DefectDojo Infrastructure Preparation Script
# Simplified version - focuses only on infrastructure setup
# Application deployment handled by GitHub Actions workflows

set -e

# Redirect output to log file
exec > >(tee /var/log/infrastructure-setup.log) 2>&1

echo "$(date): Starting infrastructure preparation for DefectDojo..."

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Create swap file for better performance on small instances (t3.micro)
echo "Setting up swap file for improved performance..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Optimize swap usage
echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf

# Install essential infrastructure packages
echo "Installing essential packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    awscli \
    python3 \
    python3-pip \
    jq

# Install Docker (essential for DefectDojo)
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Configure Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install Docker Compose standalone
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create DefectDojo directory structure
echo "Preparing DefectDojo directory..."
mkdir -p /opt/defectdojo
cd /opt/defectdojo

# Set proper permissions
chown -R ubuntu:ubuntu /opt/defectdojo

# Create infrastructure ready marker
echo "$(date): Infrastructure setup completed successfully!" > infrastructure-ready.txt
echo "Ready for application deployment via GitHub Actions workflows" >> infrastructure-ready.txt

echo "$(date): Infrastructure preparation completed!"
echo "=========================================="
echo "✅ System packages installed"
echo "🐳 Docker installed and configured"
echo "📁 DefectDojo directory prepared: /opt/defectdojo"
echo "⏳ Ready for application deployment"
echo "=========================================="
echo "Infrastructure logs: /var/log/infrastructure-setup.log"
