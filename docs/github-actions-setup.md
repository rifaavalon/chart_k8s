# GitHub Actions Setup Guide

## ⚠️ Current Issues

The GitHub Actions workflows have several issues that prevent them from running as-is:

### 1. **Terraform State Backend Not Configured**
- Backend is commented out in `terraform/main.tf`
- State won't persist between workflow runs
- Plan and apply jobs can't share state

### 2. **Ansible Can't Reach Private Instances**
- EC2 instances are in private subnets
- GitHub Actions runners are external
- No bastion host or VPN configured

### 3. **Inventory Management**
- Ansible inventory files are static
- Need dynamic inventory from Terraform outputs
- Disconnect between Terraform and Ansible

### 4. **Missing Secrets Configuration**
- Workflows reference GitHub Secrets that don't exist yet

## ✅ Solutions

### Option 1: Local Demo Only (Recommended for Presentation)

**Use the workflows as documentation only**, run deployments locally:

```bash
# Deploy locally
./scripts/deploy-environment.sh dev
```

**In your presentation, say:**
> "These GitHub Actions workflows show how we'd automate in a real environment. For this demo, I'm running locally, but in production we'd use CI/CD with proper state management and bastion hosts."

### Option 2: Fix for Actual GitHub Actions Use

If you want the workflows to actually run, here are the fixes needed:

#### Fix 1: Configure Terraform Backend

```hcl
# terraform/main.tf - Uncomment and configure
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "datadog-agent/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Setup S3 backend:**
```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### Fix 2: Use Public Subnets or Bastion Host

**Option A: Deploy instances in public subnets (easier for demo)**

Modify `terraform/modules/compute/main.tf`:
```hcl
resource "aws_instance" "app" {
  count = var.instance_count

  # Change from private to public subnets
  subnet_id = element(var.public_subnet_ids, count.index % length(var.public_subnet_ids))

  # Add public IP
  associate_public_ip_address = true

  # ... rest of config
}
```

**Option B: Add bastion host (more realistic)**

Create `terraform/modules/bastion/main.tf`:
```hcl
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = var.public_subnet_ids[0]

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name = "${var.environment}-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.environment}-bastion-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
```

Then configure Ansible to use bastion:
```ini
# ansible/inventory/dev.ini
[dev_servers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ec2-user@<bastion-ip>"'
```

#### Fix 3: Dynamic Inventory

Replace static inventory with dynamic generation:

```bash
# In GitHub Actions workflow, after terraform apply:
- name: Generate Ansible Inventory
  run: |
    cd terraform
    terraform output -json instance_private_ips | jq -r '.[]' | \
    awk '{print "instance-"NR" ansible_host="$1}' > ../ansible/inventory/dynamic.ini

    cat >> ../ansible/inventory/dynamic.ini <<EOF

    [all:vars]
    environment=dev
    ansible_user=ec2-user
    ansible_ssh_private_key_file=~/.ssh/datadog-demo-key.pem
    EOF
```

#### Fix 4: Configure GitHub Secrets

In GitHub repository settings → Secrets and variables → Actions:

```bash
# Required secrets:
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
DD_API_KEY=<your-datadog-api-key>
SSH_PRIVATE_KEY=<contents-of-your-private-key-file>
```

#### Fix 5: Updated Workflow

Here's a corrected workflow:

```yaml
name: Deploy to Development

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  TF_VERSION: 1.5.0
  ENVIRONMENT: dev

jobs:
  deploy:
    name: Deploy Infrastructure and Agents
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
          terraform_wrapper: false

      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init

      - name: Terraform Apply
        working-directory: ./terraform
        run: |
          terraform apply \
            -var-file=environments/dev/terraform.tfvars \
            -var="datadog_api_key=${{ secrets.DD_API_KEY }}" \
            -auto-approve

      - name: Get Instance IPs
        id: instances
        working-directory: ./terraform
        run: |
          echo "ips=$(terraform output -json instance_private_ips)" >> $GITHUB_OUTPUT

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install Ansible
        run: |
          pip install ansible boto3 botocore

      - name: Configure SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/datadog-demo-key.pem
          chmod 600 ~/.ssh/datadog-demo-key.pem

      - name: Generate Dynamic Inventory
        run: |
          cd terraform
          terraform output -json instance_private_ips | jq -r '.[]' | \
          awk '{print "instance-"NR" ansible_host="$1}' > ../ansible/inventory/dynamic.ini

          cat >> ../ansible/inventory/dynamic.ini <<EOF

          [all:vars]
          environment=dev
          ansible_user=ec2-user
          ansible_ssh_private_key_file=~/.ssh/datadog-demo-key.pem
          ansible_ssh_common_args='-o StrictHostKeyChecking=no'
          EOF

      - name: Wait for instances
        run: sleep 60

      - name: Deploy Datadog Agent
        working-directory: ./ansible
        run: |
          ansible-playbook -i inventory/dynamic.ini playbooks/deploy-datadog.yml
        env:
          DD_API_KEY: ${{ secrets.DD_API_KEY }}
          DD_SITE: datadoghq.com
          ANSIBLE_HOST_KEY_CHECKING: False
```

## 📝 For Your Presentation

### What to Say

**If asked about GitHub Actions:**

> "I've created GitHub Actions workflows that demonstrate our CI/CD approach. In the demo today, I'm running deployments locally for better visibility and control. In a production environment, we'd need to configure:
>
> 1. **Remote state management** - S3 backend with DynamoDB locking
> 2. **Network access** - Bastion host or GitHub-hosted runners with VPN
> 3. **Secrets management** - GitHub Secrets or integration with HashiCorp Vault
> 4. **Dynamic inventory** - Generate Ansible inventory from Terraform outputs
>
> The workflows show the automation pattern - the same commands run locally or in CI/CD."

### What to Demonstrate

1. **Show the workflow files** as documentation
2. **Run deployments locally** for the live demo
3. **Explain what changes needed** for production CI/CD
4. **Highlight this shows real-world thinking** - you understand the gaps

## 🎯 Recommended Approach for Your Presentation

### Do This:
✅ Use workflows as **reference architecture**
✅ Run deployments **locally** during demo
✅ Explain production setup requirements
✅ Show you understand the practical challenges

### Don't Do This:
❌ Try to run GitHub Actions live in demo
❌ Claim it's production-ready without caveats
❌ Hide the limitations

## 🚀 Quick Fix for Demo

If you want minimally working GitHub Actions:

1. **Use public subnets** (easier)
2. **Configure S3 backend**
3. **Set GitHub Secrets**
4. **Use dynamic inventory**

But honestly, for a 60-minute presentation, **demonstrating locally is better** because:
- More reliable
- Easier to troubleshoot
- Better visibility
- Faster iteration

The workflows still demonstrate your understanding of CI/CD patterns.
