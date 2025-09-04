#!/bin/bash

# DefectDojo Docker Build and Push Script
# This script builds and pushes Django and Nginx images to ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="defectdojo-mvp"

# Check if required tools are installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Get ECR repository URLs from Terraform output
print_status "Getting ECR repository URLs from Terraform..."
cd "$(dirname "$0")/terraform"

if [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state file not found. Please run deployment first."
    exit 1
fi

DJANGO_REPO_URL=$(terraform output -raw django_repository_url 2>/dev/null || echo "")
NGINX_REPO_URL=$(terraform output -raw nginx_repository_url 2>/dev/null || echo "")

if [ -z "$DJANGO_REPO_URL" ] || [ -z "$NGINX_REPO_URL" ]; then
    print_error "Could not get ECR repository URLs from Terraform output."
    print_error "Make sure the infrastructure is deployed first."
    exit 1
fi

print_status "Django Repository: $DJANGO_REPO_URL"
print_status "Nginx Repository: $NGINX_REPO_URL"

# Navigate to DefectDojo directory
cd ../django-DefectDojo

# Check if DefectDojo source exists
if [ ! -f "manage.py" ]; then
    print_error "DefectDojo source code not found. Make sure you're in the right directory."
    exit 1
fi

# Login to ECR
print_status "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $DJANGO_REPO_URL

# Build Django image
print_status "Building Django image..."
docker build -f Dockerfile.django-debian -t $PROJECT_NAME-django .

# Tag Django image for ECR
print_status "Tagging Django image..."
docker tag $PROJECT_NAME-django:latest $DJANGO_REPO_URL:latest

# Push Django image
print_status "Pushing Django image to ECR..."
docker push $DJANGO_REPO_URL:latest

# Build Nginx image
print_status "Building Nginx image..."
docker build -f Dockerfile.nginx-alpine -t $PROJECT_NAME-nginx .

# Tag Nginx image for ECR
print_status "Tagging Nginx image..."
docker tag $PROJECT_NAME-nginx:latest $NGINX_REPO_URL:latest

# Push Nginx image
print_status "Pushing Nginx image to ECR..."
docker push $NGINX_REPO_URL:latest

print_success "All images built and pushed successfully!"

# Update ECS service to use new images
print_status "Updating ECS service to use new images..."
cd ../sec-llm-infra/terraform

ECS_CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")

if [ -n "$ECS_CLUSTER_NAME" ] && [ -n "$ECS_SERVICE_NAME" ]; then
    print_status "Forcing ECS service update to use new images..."
    aws ecs update-service \
        --cluster $ECS_CLUSTER_NAME \
        --service $ECS_SERVICE_NAME \
        --force-new-deployment \
        --region $AWS_REGION

    print_success "ECS service update initiated!"
    print_status "You can monitor the deployment in the AWS ECS console."
else
    print_warning "Could not get ECS cluster/service names. You may need to manually update the ECS service."
fi

print_success "Docker image build and deployment completed!"

# Show next steps
echo
print_status "Next Steps:"
echo "1. Monitor the ECS service deployment in AWS console"
echo "2. Check EC2 instances are running and healthy"
echo "3. Get public IP of an EC2 instance from AWS console"
echo "4. Access DefectDojo at http://<instance-public-ip>"
echo "5. Default login: admin/admin (remember to change this!)"
