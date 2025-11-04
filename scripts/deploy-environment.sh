#!/bin/bash
#
# Deploy Environment Script
# Deploys infrastructure and Datadog agents to specified environment
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default environment
ENVIRONMENT=${1:-dev}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Datadog Agent Deployment${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'${NC}"
    echo "Usage: $0 [dev|test|prod]"
    exit 1
fi

# Check required environment variables
if [ -z "$DD_API_KEY" ]; then
    echo -e "${RED}Error: DD_API_KEY environment variable not set${NC}"
    exit 1
fi

# Production safety check
if [ "$ENVIRONMENT" == "prod" ]; then
    echo -e "${YELLOW}WARNING: You are about to deploy to PRODUCTION${NC}"
    read -p "Are you sure? (type 'yes' to continue): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

# Step 1: Terraform Infrastructure
echo -e "${BLUE}Step 1/4: Planning Terraform infrastructure...${NC}"
cd terraform

terraform init -reconfigure > /dev/null 2>&1

echo "Running terraform plan..."
if terraform plan \
    -var-file=environments/$ENVIRONMENT/terraform.tfvars \
    -out=tfplan-$ENVIRONMENT \
    -var="datadog_api_key=$DD_API_KEY"; then
    echo -e "${GREEN}✓ Terraform plan successful${NC}"
else
    echo -e "${RED}✗ Terraform plan failed${NC}"
    exit 1
fi

echo ""
read -p "Apply Terraform changes? (y/n): " apply_tf
if [ "$apply_tf" == "y" ]; then
    echo -e "${BLUE}Applying Terraform changes...${NC}"
    if terraform apply tfplan-$ENVIRONMENT; then
        echo -e "${GREEN}✓ Infrastructure deployed${NC}"
    else
        echo -e "${RED}✗ Terraform apply failed${NC}"
        exit 1
    fi
else
    echo "Terraform apply skipped"
    cd ..
    exit 0
fi

# Step 2: Get Terraform outputs
echo ""
echo -e "${BLUE}Step 2/4: Retrieving infrastructure details...${NC}"

INSTANCE_IPS=$(terraform output -json instance_private_ips | jq -r '.[]')
ALB_DNS=$(terraform output -raw alb_dns_name)

echo -e "${GREEN}✓ Infrastructure ready${NC}"
echo "  Load Balancer: $ALB_DNS"
echo "  Instances: $(echo "$INSTANCE_IPS" | wc -l)"

cd ..

# Step 3: Update Ansible inventory
echo ""
echo -e "${BLUE}Step 3/4: Updating Ansible inventory...${NC}"

INVENTORY_FILE="ansible/inventory/$ENVIRONMENT.ini"

# Backup existing inventory
if [ -f "$INVENTORY_FILE" ]; then
    cp "$INVENTORY_FILE" "$INVENTORY_FILE.bak"
fi

# Create new inventory
cat > "$INVENTORY_FILE" << EOF
[${ENVIRONMENT}_servers]
EOF

idx=1
for ip in $INSTANCE_IPS; do
    echo "${ENVIRONMENT}-instance-${idx} ansible_host=${ip}" >> "$INVENTORY_FILE"
    idx=$((idx + 1))
done

cat >> "$INVENTORY_FILE" << EOF

[${ENVIRONMENT}_servers:vars]
environment=$ENVIRONMENT
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/datadog-demo-key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo -e "${GREEN}✓ Inventory updated${NC}"

# Step 4: Deploy Datadog agents
echo ""
echo -e "${BLUE}Step 4/4: Deploying Datadog agents...${NC}"

cd ansible

# Wait for instances to be ready
echo "Waiting for instances to be accessible..."
sleep 30

if ansible-playbook \
    -i "inventory/$ENVIRONMENT.ini" \
    playbooks/deploy-datadog.yml \
    -e "environment=$ENVIRONMENT"; then
    echo -e "${GREEN}✓ Datadog agents deployed${NC}"
else
    echo -e "${RED}✗ Ansible deployment failed${NC}"
    exit 1
fi

cd ..

# Validation
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Validating deployment...${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

cd ansible

echo "Checking agent status on all hosts..."
if ansible all \
    -i "inventory/$ENVIRONMENT.ini" \
    -m shell \
    -a "datadog-agent status" \
    --become \
    > /tmp/agent-status.log 2>&1; then
    echo -e "${GREEN}✓ All agents reporting${NC}"
else
    echo -e "${YELLOW}⚠ Some agents may not be ready yet${NC}"
    echo "  Check: cat /tmp/agent-status.log"
fi

cd ..

# Summary
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Environment: $ENVIRONMENT"
echo "Load Balancer: http://$ALB_DNS"
echo "Instances deployed: $(echo "$INSTANCE_IPS" | wc -l)"
echo ""
echo "Next steps:"
echo "1. Check Datadog UI for incoming metrics"
echo "2. Test application: curl http://$ALB_DNS"
echo "3. View agent status: cd ansible && ansible all -i inventory/$ENVIRONMENT.ini -m shell -a 'datadog-agent status' --become"
echo ""
