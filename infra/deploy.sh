#!/bin/bash

# DefectDojo MVP Deployment Script
# Usage: ./deploy.sh [plan|apply|destroy]

set -e

# Configuration
export AWS_REGION="us-east-1"
export TF_VAR_project_name="defectdojo-mvp"
export TF_VAR_aws_region="$AWS_REGION"

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

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI is not configured or no credentials found."
    print_error "Please run 'aws configure' or set AWS credentials."
    exit 1
fi

# Set default action if not provided
ACTION="${1:-plan}"

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION"
    echo "Usage: $0 [plan|apply|destroy]"
    exit 1
fi

print_status "Starting DefectDojo MVP deployment with action: $ACTION"

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Check if DB password is set
if [ -z "$TF_VAR_db_password" ]; then
    print_warning "Database password not set as environment variable."
    read -s -p "Enter database password: " db_password
    echo
    export TF_VAR_db_password="$db_password"
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Format check
print_status "Checking Terraform format..."
terraform fmt -check=true -recursive || {
    print_warning "Terraform files are not properly formatted. Running terraform fmt..."
    terraform fmt -recursive
}

# Execute action
case $ACTION in
    "plan")
        print_status "Running Terraform plan..."
        terraform plan
        ;;
    "apply")
        print_status "Running Terraform apply..."
        terraform plan -out=tfplan
        echo
        print_warning "This will create AWS resources that may incur costs."
        read -p "Do you want to continue? (yes/no): " confirm
        if [[ $confirm == "yes" ]]; then
            terraform apply tfplan
            print_success "Infrastructure deployed successfully!"
            echo
            print_status "Getting outputs..."
            terraform output
        else
            print_status "Deployment cancelled."
            rm -f tfplan
        fi
        ;;
    "destroy")
        print_status "Running Terraform destroy..."
        terraform plan -destroy
        echo
        print_warning "This will DESTROY all AWS resources!"
        read -p "Are you sure you want to destroy the infrastructure? (yes/no): " confirm
        if [[ $confirm == "yes" ]]; then
            terraform destroy -auto-approve
            print_success "Infrastructure destroyed successfully!"
        else
            print_status "Destruction cancelled."
        fi
        ;;
esac

print_success "DefectDojo MVP deployment script completed!"

# Display next steps
if [[ $ACTION == "apply" ]]; then
    echo
    print_status "Next Steps:"
    echo "1. Build and push Docker images to the ECR repositories"
    echo "2. Check ECS service status in AWS console"
    echo "3. Find EC2 instance public IPs to access the application"
    echo "4. Access DefectDojo at http://<instance-public-ip>"
fi
