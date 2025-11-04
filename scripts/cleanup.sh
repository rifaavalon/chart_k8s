#!/bin/bash
#
# Cleanup Script
# Destroys demo infrastructure
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT=${1:-dev}

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}Datadog Demo Cleanup${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'${NC}"
    echo "Usage: $0 [dev|test|prod]"
    exit 1
fi

echo -e "${RED}WARNING: This will destroy all infrastructure in $ENVIRONMENT${NC}"
read -p "Are you sure? (type 'yes' to continue): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

cd terraform

echo ""
echo "Running terraform destroy..."
if terraform destroy \
    -var-file=environments/$ENVIRONMENT/terraform.tfvars \
    -var="datadog_api_key=${DD_API_KEY:-dummy}" \
    -auto-approve; then
    echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
else
    echo -e "${RED}✗ Terraform destroy failed${NC}"
    echo "You may need to manually clean up resources in AWS console"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
echo ""
