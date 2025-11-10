#!/bin/bash

# EKS Infrastructure Setup Script
# This script helps you set up and deploy EKS infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed ($(command -v $1))"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

# Main script
print_header "EKS Infrastructure Setup"

# Check prerequisites
print_header "Checking Prerequisites"

all_present=true

if ! check_command terraform; then
    print_warning "Install Terraform: https://www.terraform.io/downloads"
    all_present=false
fi

if ! check_command aws; then
    print_warning "Install AWS CLI: https://aws.amazon.com/cli/"
    all_present=false
fi

if ! check_command kubectl; then
    print_warning "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
    all_present=false
fi

if ! check_command python3; then
    print_warning "Install Python 3: https://www.python.org/downloads/"
    all_present=false
fi

if [ "$all_present" = false ]; then
    print_error "Some prerequisites are missing. Please install them and try again."
    exit 1
fi

# Check AWS credentials
print_header "Checking AWS Credentials"

if aws sts get-caller-identity &> /dev/null; then
    print_success "AWS credentials are configured"
    aws sts get-caller-identity
else
    print_error "AWS credentials are not configured"
    print_warning "Run 'aws configure' to set up your credentials"
    exit 1
fi

# Select environment
print_header "Select Environment"

echo "Available environments:"
echo "1) dev   - Development environment (small, cost-optimized)"
echo "2) stg   - Staging environment (medium, production-like)"
echo "3) prod  - Production environment (large, high-availability)"
echo ""
read -p "Select environment (1-3): " env_choice

case $env_choice in
    1) ENVIRONMENT="dev" ;;
    2) ENVIRONMENT="stg" ;;
    3) ENVIRONMENT="prod" ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_success "Selected environment: $ENVIRONMENT"

# Navigate to terraform directory
cd ../terraform/kubernetes

# Initialize Terraform
print_header "Initializing Terraform"

terraform init
print_success "Terraform initialized"

# Terraform plan
print_header "Running Terraform Plan"

terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars -out=${ENVIRONMENT}.tfplan
print_success "Terraform plan completed"

# Ask for confirmation
print_header "Deployment Confirmation"

echo -e "${YELLOW}You are about to deploy to: ${ENVIRONMENT}${NC}"
echo ""
echo "This will create:"
echo "  • EKS cluster"
echo "  • VPC with public and private subnets"
echo "  • NAT gateways (if enabled)"
echo "  • Security groups"
echo "  • IAM roles and policies"
echo "  • Node groups with EC2 instances"
echo ""
read -p "Do you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_warning "Deployment cancelled"
    exit 0
fi

# Apply Terraform
print_header "Applying Terraform Configuration"

terraform apply ${ENVIRONMENT}.tfplan
print_success "Terraform apply completed"

# Get cluster name from output
CLUSTER_NAME=$(terraform output -raw cluster_id)

# Configure kubectl
print_header "Configuring kubectl"

aws eks update-kubeconfig --region us-east-1 --name ${CLUSTER_NAME}
print_success "kubectl configured for cluster: ${CLUSTER_NAME}"

# Verify cluster
print_header "Verifying Cluster"

echo "Cluster Info:"
kubectl cluster-info

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "Namespaces:"
kubectl get namespaces

# Install Python dependencies
print_header "Installing Python Dependencies"

cd ../../scripts
pip install -r requirements.txt
print_success "Python dependencies installed"

# Run cluster audit
print_header "Running Cluster Audit"

python cluster_audit.py --environment ${ENVIRONMENT}
print_success "Cluster audit completed"

# Print completion message
print_header "Setup Complete!"

echo -e "${GREEN}Your EKS cluster is ready!${NC}"
echo ""
echo "Cluster Name: ${CLUSTER_NAME}"
echo "Environment: ${ENVIRONMENT}"
echo ""
echo "Next steps:"
echo "  1. Review the cluster audit results in ../output/"
echo "  2. Deploy your applications using kubectl"
echo "  3. Configure monitoring and logging"
echo ""
echo "Useful commands:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl cluster-info"
echo ""
echo "To destroy the cluster:"
echo "  cd ../terraform/kubernetes"
echo "  terraform destroy -var-file=environments/${ENVIRONMENT}/terraform.tfvars"
echo ""

print_success "All done!"
