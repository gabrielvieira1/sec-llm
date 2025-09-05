#!/bin/bash

# DefectDojo Installation Script for Ubuntu 22.04 LTS
# This script replicates the exact working configuration from local development

set -e

# Redirect output to log file
exec > >(tee /var/log/defectdojo-install.log) 2>&1

echo "$(date): Starting DefectDojo installation with proven configuration..."

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
    jq \
    postgresql-client

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

# Download our repository app folder instead of cloning DefectDojo
echo "Downloading DefectDojo app configuration from our repository..."
# The app deploy workflow will copy the app folder here
# For now, we just prepare the directory structure

# Wait for database URL to be available in SSM
echo "Waiting for database URL in SSM Parameter Store..."
for i in {1..30}; do
    if DB_URL=$(aws ssm get-parameter --name "PROJECT_NAME_PLACEHOLDER-database-url" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null); then
        echo "Database URL retrieved: $DB_URL"
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

# Extract database components from URL
DB_HOST=$(echo "$DB_URL" | sed -n 's|.*@\([^:]*\):.*|\1|p')
DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')

echo "Database host: $DB_HOST"
echo "Database port: $DB_PORT"

# Test database connectivity (same as local troubleshooting)
echo "Testing database connectivity..."
export PGPASSWORD="MySecurePassword123!"
for i in {1..30}; do
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U defectdojo -d defectdojo; then
        echo "Database is accepting connections!"
        break
    else
        echo "Waiting for database... attempt $i/30"
        sleep 10
    fi
    
    if [ $i -eq 30 ]; then
        echo "Database connectivity failed after 30 attempts. Exiting."
        exit 1
    fi
done

# Create .env.local (exact copy from working local setup)
cat > .env.local << EOF
# DefectDojo Local Development com RDS AWS
# Arquivo gerado automaticamente em $(date)

# Database Configuration (AWS RDS)
DD_DATABASE_URL=$DB_URL

# DefectDojo Configuration
DD_DEBUG=True
DD_ALLOWED_HOSTS=*
DD_SECRET_KEY=hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq
DD_CREDENTIAL_AES_256_KEY=&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw
DD_ENABLE_AUDITLOG=False

# Admin User Configuration
DD_ADMIN_USER=admin
DD_ADMIN_MAIL=admin@defectdojo.local
DD_ADMIN_PASSWORD=DefectDojoMVP2024!
DD_ADMIN_FIRST_NAME=Admin
DD_ADMIN_LAST_NAME=User
DD_INITIALIZE=true

# Redis Configuration (local)
DD_CELERY_BROKER_URL=redis://redis:6379/0

# Media files
DD_MEDIA_ROOT=/app/media

# Timezone
DD_TIME_ZONE=America/Sao_Paulo
EOF

# Create docker-compose.rds.yml (exact copy from working local setup)
cat > docker-compose.rds.yml << EOF
# docker-compose para DefectDojo com RDS AWS
# Execute com: docker-compose -f docker-compose.rds.yml up -d

services:
  nginx:
    build:
      context: ./
      dockerfile: "Dockerfile.nginx-alpine"
    image: "defectdojo/defectdojo-nginx:latest"
    depends_on:
      uwsgi:
        condition: service_started
    environment:
      NGINX_METRICS_ENABLED: "false"
      DD_UWSGI_HOST: "uwsgi"
      DD_UWSGI_PORT: "3031"
    volumes:
      - defectdojo_media:/usr/share/nginx/html/media
    ports:
      - "80:8080"
      - "8080:8080"
      - "8443:8443"

  uwsgi:
    build:
      context: ./
      dockerfile: "Dockerfile.django-debian"
      target: django
    image: "defectdojo/defectdojo-django:latest"
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started
    entrypoint: ["/entrypoint-uwsgi.sh"]
    env_file:
      - .env.local
    environment:
      DD_DEBUG: "True"
      DD_DJANGO_METRICS_ENABLED: "False"
      DD_ALLOWED_HOSTS: "*"
      DD_DATABASE_URL: $DB_URL
      DD_CELERY_BROKER_URL: redis://redis:6379/0
      DD_SECRET_KEY: "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq"
      DD_CREDENTIAL_AES_256_KEY: "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
    volumes:
      - type: bind
        source: ./docker/extra_settings
        target: /app/docker/extra_settings
      - "defectdojo_media:/app/media"

  celerybeat:
    image: "defectdojo/defectdojo-django:latest"
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started
    entrypoint: ["/entrypoint-celery-beat.sh"]
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DB_URL
      DD_CELERY_BROKER_URL: redis://redis:6379/0
      DD_SECRET_KEY: "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq"
      DD_CREDENTIAL_AES_256_KEY: "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
    volumes:
      - type: bind
        source: ./docker/extra_settings
        target: /app/docker/extra_settings

  celeryworker:
    image: "defectdojo/defectdojo-django:latest"
    depends_on:
      initializer:
        condition: service_completed_successfully
      redis:
        condition: service_started
    entrypoint: ["/entrypoint-celery-worker.sh"]
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DB_URL
      DD_CELERY_BROKER_URL: redis://redis:6379/0
      DD_SECRET_KEY: "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq"
      DD_CREDENTIAL_AES_256_KEY: "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
    volumes:
      - type: bind
        source: ./docker/extra_settings
        target: /app/docker/extra_settings
      - "defectdojo_media:/app/media"

  initializer:
    image: "defectdojo/defectdojo-django:latest"
    entrypoint: ["/entrypoint-initializer.sh"]
    env_file:
      - .env.local
    environment:
      DD_DATABASE_URL: $DB_URL
      DD_ADMIN_USER: "admin"
      DD_ADMIN_MAIL: "admin@defectdojo.local"
      DD_ADMIN_PASSWORD: "DefectDojoMVP2024!"
      DD_ADMIN_FIRST_NAME: "Admin"
      DD_ADMIN_LAST_NAME: "User"
      DD_INITIALIZE: "true"
      DD_ENABLE_AUDITLOG: "False"
      DD_SECRET_KEY: "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq"
      DD_CREDENTIAL_AES_256_KEY: "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
    volumes:
      - type: bind
        source: ./docker/extra_settings
        target: /app/docker/extra_settings

  redis:
    image: redis:7.2.10-alpine@sha256:395ccd7ee4db0867de0d0410f4712a9e0331cff9fdbd864f71ec0f7982d3ffe6
    volumes:
      - defectdojo_redis:/data

volumes:
  defectdojo_media: {}
  defectdojo_redis: {}
EOF

# Set proper permissions
chown -R ubuntu:ubuntu /opt/defectdojo

# Create a marker file indicating the infrastructure is ready
echo "$(date): Infrastructure setup completed. Ready for app deployment." > /opt/defectdojo/infrastructure-ready.txt

# The actual DefectDojo installation will be handled by the app-deploy workflow
# This includes:
# 1. Copying the app folder from our repository
# 2. Running the exact Docker commands that worked locally:
#    - docker-compose -f docker-compose.rds.yml run --rm --entrypoint="" -e DD_ENABLE_AUDITLOG=False initializer bash -c "cd /app && python manage.py migrate --run-syncdb"
#    - docker-compose -f docker-compose.rds.yml run --rm --entrypoint="" -e DD_ENABLE_AUDITLOG=False initializer bash -c "cd /app && echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@defectdojo.local', 'DefectDojoMVP2024!')\" | python manage.py shell"
#    - docker-compose -f docker-compose.rds.yml up -d --remove-orphans

echo "$(date): Infrastructure deployment completed successfully!"
echo "=========================================="
echo "� Infrastructure Ready!"
echo "� DefectDojo directory: /opt/defectdojo"  
echo "🗄️ Database: RDS PostgreSQL ready"
echo "⏳ Waiting for app deployment via GitHub Actions..."
echo "=========================================="
echo "Infrastructure setup logs saved to: /var/log/defectdojo-install.log"
