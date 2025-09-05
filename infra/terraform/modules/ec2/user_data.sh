#!/bin/bash

# DefectDojo Installation Script for Ubuntu 22.04 LTS
# This script installs Docker, Docker Compose, and sets up DefectDojo

set -e

# Redirect output to log file
exec > >(tee /var/log/defectdojo-install.log) 2>&1

echo "$(date): Starting DefectDojo installation..."

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install required packages
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

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Python packages for DefectDojo setup
pip3 install cryptography

# Create DefectDojo directory
mkdir -p /opt/defectdojo
cd /opt/defectdojo

# Clone DefectDojo repository
git clone https://github.com/DefectDojo/django-DefectDojo.git .

# Wait for database URL to be available in SSM
echo "Waiting for database URL in SSM Parameter Store..."
for i in {1..30}; do
    if DB_URL=$(aws ssm get-parameter --name "${project_name}-database-url" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null); then
        echo "Database URL retrieved successfully"
        break
    else
        echo "Waiting for database URL... attempt $i/30"
        sleep 10
    fi
    
    if [ $i -eq 30 ]; then
        echo "Failed to get database URL from SSM after 30 attempts. Exiting."
        exit 1
    fi
done

# Create environment file for DefectDojo
cat > .env.prod << EOF
# DefectDojo Production Configuration
DD_DEBUG=False
DD_ALLOWED_HOSTS=*
DD_DATABASE_URL=${DB_URL}
DD_SECRET_KEY=$(openssl rand -base64 32)
DD_CREDENTIAL_AES_256_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")

# Media files configuration
DD_MEDIA_ROOT=/app/media

# Additional settings
DD_TIME_ZONE=America/Sao_Paulo
DD_LANG=pt-BR
DD_SITE_ID=1
DD_USE_TZ=True

# Email settings
DD_EMAIL_URL=console://

# WhiteNoise for static files
DD_WHITENOISE_USE_FINDERS=True
DD_WHITENOISE_STATIC_PREFIX=/static/

# Security settings
DD_SESSION_COOKIE_SECURE=False
DD_CSRF_COOKIE_SECURE=False
DD_SECURE_SSL_REDIRECT=False
DD_SECURE_BROWSER_XSS_FILTER=True
DD_SECURE_CONTENT_TYPE_NOSNIFF=True

# Admin user settings
DD_INITIALIZE=true
DD_ADMIN_USER=admin
DD_ADMIN_MAIL=admin@defectdojo.local
DD_ADMIN_PASSWORD=DefectDojoMVP2024!
DD_ADMIN_FIRST_NAME=Admin
DD_ADMIN_LAST_NAME=User
EOF

# Create docker-compose.override.yml for production
cat > docker-compose.override.yml << 'EOF'
version: '3.7'
services:
  nginx:
    image: defectdojo/defectdojo-nginx:latest
    depends_on:
      - uwsgi
    ports:
      - "80:8080"
      - "8080:8080"
    volumes:
      - defectdojo_media:/usr/share/nginx/html/media
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3

  uwsgi:
    image: defectdojo/defectdojo-django:latest
    env_file:
      - .env.prod
    volumes:
      - defectdojo_media:/app/media
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "manage.py", "check"]
      interval: 30s
      timeout: 10s
      retries: 3

  celerybeat:
    image: defectdojo/defectdojo-django:latest
    depends_on:
      - redis
    env_file:
      - .env.prod
    command: ["/wait-for-it.sh", "redis:6379", "-t", "30", "--", "/app/docker/entrypoint-celery-beat.sh"]
    volumes:
      - defectdojo_media:/app/media
    restart: unless-stopped

  celeryworker:
    image: defectdojo/defectdojo-django:latest
    depends_on:
      - redis
    env_file:
      - .env.prod
    command: ["/wait-for-it.sh", "redis:6379", "-t", "30", "--", "/app/docker/entrypoint-celery-worker.sh"]
    volumes:
      - defectdojo_media:/app/media
    restart: unless-stopped

  initializer:
    image: defectdojo/defectdojo-django:latest
    env_file:
      - .env.prod
    command: ["/wait-for-it.sh", "redis:6379", "-t", "30", "--", "/app/docker/entrypoint-initializer.sh"]
    volumes:
      - defectdojo_media:/app/media

  redis:
    image: redis:7.2-alpine
    volumes:
      - defectdojo_redis:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  defectdojo_media: {}
  defectdojo_redis: {}
EOF

# Set proper permissions
chown -R ubuntu:ubuntu /opt/defectdojo

# Create systemd service for DefectDojo
cat > /etc/systemd/system/defectdojo.service << 'EOF'
[Unit]
Description=DefectDojo Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/defectdojo
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=root
Group=root
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable DefectDojo service
systemctl daemon-reload
systemctl enable defectdojo

# Pull images and start DefectDojo
cd /opt/defectdojo
echo "Pulling DefectDojo images..."
docker-compose pull

echo "Starting DefectDojo..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for DefectDojo to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:8080/ > /dev/null 2>&1; then
        echo "DefectDojo is ready!"
        break
    else
        echo "Waiting for DefectDojo... attempt $i/30"
        sleep 10
    fi
done

echo "$(date): DefectDojo installation completed successfully"
echo "Access DefectDojo at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Default login: admin / DefectDojoMVP2024!"
echo "User data script completed successfully"
reboot
