#!/bin/bash
#
# Demo Setup Script
# Prepares the environment for the live demo
#

set -e

echo "========================================="
echo "Datadog Agent Deployment - Demo Setup"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI not found${NC}"
    echo "  Install: https://aws.amazon.com/cli/"
    exit 1
else
    echo -e "${GREEN}✓ AWS CLI installed${NC}"
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found${NC}"
    echo "  Install: https://www.terraform.io/downloads"
    exit 1
else
    TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ Terraform installed${NC} ($TERRAFORM_VERSION)"
fi

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}✗ Ansible not found${NC}"
    echo "  Install: pip install ansible"
    exit 1
else
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ Ansible installed${NC} ($ANSIBLE_VERSION)"
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    exit 1
else
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓ Python installed${NC} ($PYTHON_VERSION)"
fi

echo ""

# Check environment variables
echo "Checking environment variables..."
echo ""

if [ -z "$DD_API_KEY" ]; then
    echo -e "${YELLOW}⚠ DD_API_KEY not set${NC}"
    read -p "Enter your Datadog API key: " DD_API_KEY
    export DD_API_KEY
    echo "export DD_API_KEY=$DD_API_KEY" >> ~/.bash_profile
    echo -e "${GREEN}✓ DD_API_KEY set${NC}"
else
    echo -e "${GREEN}✓ DD_API_KEY configured${NC}"
fi

if [ -z "$DD_SITE" ]; then
    export DD_SITE="datadoghq.com"
    echo "export DD_SITE=datadoghq.com" >> ~/.bash_profile
    echo -e "${GREEN}✓ DD_SITE set to datadoghq.com${NC}"
else
    echo -e "${GREEN}✓ DD_SITE configured${NC} ($DD_SITE)"
fi

if [ -z "$AWS_REGION" ]; then
    export AWS_REGION="us-east-1"
    echo -e "${YELLOW}⚠ AWS_REGION not set, using us-east-1${NC}"
fi

echo ""

# Check AWS credentials
echo "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    echo -e "${GREEN}✓ AWS credentials valid${NC}"
    echo "  Account: $AWS_ACCOUNT"
    echo "  User: $AWS_USER"
else
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo "  Run: aws configure"
    exit 1
fi

echo ""

# Check/create SSH key
echo "Checking SSH key..."
if [ ! -f ~/.ssh/datadog-demo-key.pem ]; then
    echo -e "${YELLOW}⚠ SSH key not found${NC}"
    echo "Creating SSH key pair in AWS..."
    aws ec2 create-key-pair \
        --key-name datadog-demo-key \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/datadog-demo-key.pem
    chmod 600 ~/.ssh/datadog-demo-key.pem
    echo -e "${GREEN}✓ SSH key created${NC}"
else
    echo -e "${GREEN}✓ SSH key exists${NC}"
fi

echo ""

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
if terraform init > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Terraform initialized${NC}"
else
    echo -e "${RED}✗ Terraform initialization failed${NC}"
    exit 1
fi
cd ..

echo ""

# Install Ansible dependencies
echo "Installing Ansible dependencies..."
if pip3 install -q boto3 botocore; then
    echo -e "${GREEN}✓ Ansible dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ Failed to install Ansible dependencies${NC}"
fi

echo ""

# Create demo script
echo "Creating demo helper aliases..."
cat > ~/.datadog-demo-aliases << 'EOF'
# Datadog Demo Aliases
alias demo-tf-plan='cd ~/datadog_pres/terraform && terraform plan -var-file=environments/dev/terraform.tfvars'
alias demo-tf-apply='cd ~/datadog_pres/terraform && terraform apply -var-file=environments/dev/terraform.tfvars'
alias demo-tf-destroy='cd ~/datadog_pres/terraform && terraform destroy -var-file=environments/dev/terraform.tfvars'
alias demo-ansible='cd ~/datadog_pres/ansible && ansible-playbook -i inventory/dev.ini playbooks/deploy-datadog.yml'
alias demo-status='cd ~/datadog_pres/ansible && ansible all -i inventory/dev.ini -m shell -a "datadog-agent status" --become'
alias demo-logs='cd ~/datadog_pres && tail -f /tmp/demo-deployment.log'
EOF

if ! grep -q "source ~/.datadog-demo-aliases" ~/.bash_profile; then
    echo "source ~/.datadog-demo-aliases" >> ~/.bash_profile
fi

echo -e "${GREEN}✓ Demo aliases created${NC}"
echo ""
echo "Available aliases:"
echo "  demo-tf-plan    - Run Terraform plan for dev environment"
echo "  demo-tf-apply   - Apply Terraform changes for dev"
echo "  demo-tf-destroy - Destroy dev infrastructure"
echo "  demo-ansible    - Deploy Datadog agents to dev"
echo "  demo-status     - Check agent status on all hosts"

echo ""
echo "========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review the architecture: cat diagrams/architecture.md"
echo "2. Review the project plan: cat docs/project-plan.md"
echo "3. Review the presentation script: cat docs/presentation-script.md"
echo "4. Start demo: demo-tf-plan"
echo ""
echo "To reload aliases, run: source ~/.bash_profile"
echo ""
