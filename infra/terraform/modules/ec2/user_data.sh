#!/bin/bash

# User Data Script for DefectDojo EC2 Instance (Amazon Linux 2023)
# This script prepares the instance for Ansible configuration

set -e

# Update system (Amazon Linux 2023)
dnf update -y

# Install required packages for Ansible
dnf install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    git \
    htop \
    unzip \
    docker \
    awscli

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directory for DefectDojo
mkdir -p /opt/defectdojo
chown ec2-user:ec2-user /opt/defectdojo

# Create directory for logs
mkdir -p /var/log/defectdojo
chown ec2-user:ec2-user /var/log/defectdojo

# Install CloudWatch agent for monitoring
dnf install -y amazon-cloudwatch-agent

# Create a marker file to indicate user data completion
touch /opt/user-data-complete
chown ec2-user:ec2-user /opt/user-data-complete

# Log completion
echo "$(date): User data script completed successfully" >> /var/log/user-data.log

# Reboot to ensure all changes take effect
echo "User data script completed successfully"
reboot
