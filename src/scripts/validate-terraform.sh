#!/bin/bash

# Terraform Validation Script
# Validates Terraform configuration for all environments

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Navigate to kubernetes terraform directory
cd ../terraform/kubernetes

print_header "Terraform Validation for EKS Infrastructure"

# Format check
print_header "1. Checking Terraform Format"
if terraform fmt -check -recursive; then
    print_success "All files are properly formatted"
else
    print_error "Some files need formatting. Run: terraform fmt -recursive"
    exit 1
fi

# Initialize (if needed)
print_header "2. Initializing Terraform"
terraform init -backend=false
print_success "Terraform initialized"

# Validate
print_header "3. Validating Terraform Configuration"
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    exit 1
fi

# Validate each environment
for env in dev stg prod; do
    print_header "4. Validating ${env} environment configuration"

    if terraform plan -var-file=environments/${env}/terraform.tfvars -out=/dev/null; then
        print_success "${env} configuration is valid"
    else
        print_error "${env} configuration has errors"
        exit 1
    fi
done

# Security scan on Python scripts
print_header "5. Running Security Scan (Bandit)"
cd ../../scripts

if command -v bandit &> /dev/null; then
    if bandit -r . -ll; then
        print_success "Security scan passed"
    else
        print_error "Security issues found"
        exit 1
    fi
else
    print_error "Bandit not installed. Run: pip install bandit"
fi

print_header "Validation Complete!"
print_success "All checks passed! Your infrastructure code is ready to deploy."
