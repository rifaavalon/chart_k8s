#!/bin/bash
#
# Setup GitHub Actions for Datadog Deployment
# Creates S3 backend and configures GitHub Secrets
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}GitHub Actions Setup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI not found${NC}"
    exit 1
else
    echo -e "${GREEN}✓ AWS CLI installed${NC}"
fi

if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠ GitHub CLI not found (optional)${NC}"
    echo "  Install to automatically configure GitHub Secrets: https://cli.github.com/"
    GH_CLI_AVAILABLE=false
else
    echo -e "${GREEN}✓ GitHub CLI installed${NC}"
    GH_CLI_AVAILABLE=true
fi

echo ""

# Verify AWS credentials
echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo "  Run: aws configure"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="${AWS_REGION:-us-east-1}"
echo -e "${GREEN}✓ AWS Account: $AWS_ACCOUNT${NC}"
echo -e "${GREEN}✓ AWS Region: $AWS_REGION${NC}"
echo ""

# S3 bucket configuration
BUCKET_NAME="datadog-demo-terraform-state"
DYNAMODB_TABLE="datadog-demo-terraform-locks"

echo "Creating Terraform state backend..."
echo ""

# Create S3 bucket
echo "1. Creating S3 bucket: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Bucket already exists${NC}"
else
    if [ "$AWS_REGION" == "us-east-1" ]; then
        aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
    else
        aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    echo -e "${GREEN}✓ Bucket created${NC}"
fi

# Enable versioning
echo "2. Enabling bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
echo -e "${GREEN}✓ Versioning enabled${NC}"

# Enable encryption
echo "3. Enabling bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'
echo -e "${GREEN}✓ Encryption enabled${NC}"

# Block public access
echo "4. Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo -e "${GREEN}✓ Public access blocked${NC}"

echo ""

# Create DynamoDB table
echo "Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
    echo -e "${YELLOW}⚠ Table already exists${NC}"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        > /dev/null
    echo -e "${GREEN}✓ DynamoDB table created${NC}"

    echo "Waiting for table to become active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    echo -e "${GREEN}✓ Table is active${NC}"
fi

echo ""

# Create/verify SSH key
echo "Checking SSH key pair..."
KEY_NAME="datadog-demo-key"
KEY_FILE="$HOME/.ssh/datadog-demo-key.pem"

if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo -e "${YELLOW}⚠ Key pair already exists in AWS${NC}"
    if [ ! -f "$KEY_FILE" ]; then
        echo -e "${RED}✗ Private key file not found: $KEY_FILE${NC}"
        echo "  You need the private key file to proceed."
        echo "  Either:"
        echo "  1. Restore the key from backup"
        echo "  2. Delete the key in AWS and re-run this script"
        exit 1
    fi
else
    echo "Creating new SSH key pair..."
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --region "$AWS_REGION" \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    echo -e "${GREEN}✓ SSH key created: $KEY_FILE${NC}"
fi

echo ""

# Datadog API key
echo "Datadog Configuration..."
if [ -z "$DD_API_KEY" ]; then
    echo -e "${YELLOW}⚠ DD_API_KEY environment variable not set${NC}"
    read -sp "Enter your Datadog API key: " DD_API_KEY
    echo ""
    export DD_API_KEY
else
    echo -e "${GREEN}✓ DD_API_KEY is set${NC}"
fi

echo ""

# GitHub Secrets configuration
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}GitHub Secrets Configuration${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

if [ "$GH_CLI_AVAILABLE" = true ]; then
    echo "Would you like to automatically configure GitHub Secrets? (requires 'gh' CLI)"
    read -p "Configure now? (y/n): " configure_secrets

    if [ "$configure_secrets" == "y" ]; then
        echo ""
        echo "Checking GitHub authentication..."
        if ! gh auth status &>/dev/null; then
            echo "Please authenticate with GitHub:"
            gh auth login
        fi

        echo "Setting GitHub Secrets..."

        # AWS credentials
        if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
            echo -e "${YELLOW}⚠ AWS credentials not in environment variables${NC}"
            echo "Please enter AWS credentials for GitHub Actions:"
            read -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
            read -sp "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
            echo ""
        fi

        gh secret set AWS_ACCESS_KEY_ID -b"$AWS_ACCESS_KEY_ID"
        gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SECRET_ACCESS_KEY"
        gh secret set DD_API_KEY -b"$DD_API_KEY"
        gh secret set SSH_PRIVATE_KEY < "$KEY_FILE"

        echo -e "${GREEN}✓ GitHub Secrets configured${NC}"
    else
        echo "Skipping automatic configuration."
    fi
fi

if [ "$GH_CLI_AVAILABLE" = false ] || [ "$configure_secrets" != "y" ]; then
    echo "Manual GitHub Secrets Configuration Required:"
    echo ""
    echo "Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
    echo ""
    echo "Add the following secrets:"
    echo ""
    echo "1. AWS_ACCESS_KEY_ID"
    echo "   Value: Your AWS access key"
    echo ""
    echo "2. AWS_SECRET_ACCESS_KEY"
    echo "   Value: Your AWS secret key"
    echo ""
    echo "3. DD_API_KEY"
    echo "   Value: Your Datadog API key"
    echo ""
    echo "4. SSH_PRIVATE_KEY"
    echo "   Value: Contents of $KEY_FILE"
    echo "   Run: cat $KEY_FILE"
    echo ""
fi

echo ""

# Setup GitHub Environments (if using gh CLI)
if [ "$GH_CLI_AVAILABLE" = true ] && [ "$configure_secrets" == "y" ]; then
    echo "Setting up GitHub Environments for approval gates..."
    echo ""
    echo -e "${YELLOW}Note: Environment protection rules must be configured manually in GitHub UI${NC}"
    echo "Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/environments"
    echo ""
    echo "Create these environments:"
    echo "  - test (add required reviewers)"
    echo "  - production (add required reviewers + wait timer)"
    echo ""
fi

# Summary
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Resources created:"
echo "  ✓ S3 Bucket: $BUCKET_NAME"
echo "  ✓ DynamoDB Table: $DYNAMODB_TABLE"
echo "  ✓ SSH Key Pair: $KEY_NAME"
echo ""
echo "Next steps:"
echo "1. Push your code to GitHub"
echo "2. Configure GitHub Environments (test, production) with approval rules"
echo "3. Test the workflow:"
echo "   - Push to main branch (triggers dev deployment)"
echo "   - Manually trigger test deployment from Actions tab"
echo "   - Manually trigger prod deployment from Actions tab"
echo ""
echo "Local testing:"
echo "  ./scripts/deploy-environment.sh dev"
echo ""
echo "For local Terraform use (without remote backend):"
echo "  cd terraform"
echo "  terraform init -backend=false"
echo ""
