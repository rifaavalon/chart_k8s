# Kubernetes Infrastructure Documentation

## Project Overview

This repository contains production-ready infrastructure code for deploying and managing Amazon EKS (Elastic Kubernetes Service) clusters across multiple environments using Terraform and GitHub Actions CI/CD.


## Project Structure

```
.
├── src/
│   ├── output/                      # Audit results and logs
│   ├── scripts/                     # Python scripts and utilities
│   │   ├── cluster_audit.py        # EKS cluster audit tool
│   │   ├── Dockerfile              # Container image for audit script
│   │   └── requirements.txt        # Python dependencies
│   └── terraform/
│       └── kubernetes/             # Kubernetes/EKS infrastructure
│           ├── main.tf             # Root module configuration
│           ├── variables.tf        # Variable definitions
│           ├── outputs.tf          # Output values
│           ├── README.md           # Detailed documentation
│           ├── environments/       # Environment-specific configs
│           │   ├── dev/
│           │   │   └── terraform.tfvars
│           │   ├── stg/
│           │   │   └── terraform.tfvars
│           │   └── prod/
│           │       └── terraform.tfvars
│           └── modules/
│               └── eks-cluster/    # Reusable EKS module
│                   ├── main.tf
│                   ├── variables.tf
│                   ├── outputs.tf
│                   └── templates/
│                       └── aws-auth-cm.yaml.tpl
└── .github/
    └── workflows/
        └── eks-terraform.yml       # CI/CD pipeline
```

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│                   (Infrastructure as Code)                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions CI/CD                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌─────────┐ │
│  │ Validate │→ │   Test   │→ │Infrastructure│→ │ Deploy  │ │
│  │  & Scan  │  │  (Plan)  │  │ (Apply/Dest) │  │  to K8s │ │
│  └──────────┘  └──────────┘  └──────────────┘  └─────────┘ │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                       AWS Cloud                              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           VPC (per environment)                        │ │
│  │                                                        │ │
│  │  Public Subnets (NAT GW, ALB)                         │ │
│  │  Private Subnets (EKS Nodes)                          │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │         EKS Control Plane                        │ │ │
│  │  │         (Managed by AWS)                         │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │         EKS Node Groups                          │ │ │
│  │  │  • Critical (On-Demand)                          │ │ │
│  │  │  • General (On-Demand)                           │ │ │
│  │  │  • Batch (Spot Instances)                        │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  CloudWatch Logs & Monitoring                                │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Infrastructure as Code (Terraform)

- **Reusable EKS Module**: Modular design for easy reuse across environments
- **Environment Separation**: Dedicated configurations for dev, stg, and prod
- **State Management**: Local backend for testing (can be upgraded to S3/remote)
- **Variable Validation**: Built-in validation for all critical variables

### 2. Kubernetes Knowledge

- **Multi-AZ High Availability**: Nodes distributed across availability zones
- **Auto-scaling Node Groups**: Dynamic scaling based on workload demand
- **IRSA Support**: IAM Roles for Service Accounts for secure pod-level permissions
- **Network Policies**: Support for Kubernetes network policies
- **RBAC Configuration**: Comprehensive role-based access control

### 3. Python Scripting & Testing

- **Cluster Audit Script**: Comprehensive health checking and reporting
- **Automated Testing**: Security scanning with Bandit
- **Container Image**: Dockerized audit script for portability
- **Output Management**: JSON-formatted audit results

### 4. CI/CD Pipeline (GitHub Actions)

**Pipeline Stages:**

1. **Validate**
   - Terraform format checking
   - Terraform validation
   - Security scanning (Bandit for Python)
   - Results posted to PRs

2. **Test**
   - Terraform plan for all environments (dev, stg, prod)
   - Plan artifacts uploaded for review
   - Matrix strategy for parallel execution

3. **Infrastructure** (Manual Trigger)
   - Terraform apply with approval gates
   - Terraform destroy with safeguards
   - Environment-specific deployments

4. **Deploy**
   - Build and push container images to ECR
   - Deploy applications to Kubernetes
   - Run automated cluster audits
   - Upload audit results as artifacts

### 5. Git Best Practices

- **Branch Protection**: Main branch protected
- **Pull Request Reviews**: Required for infrastructure changes
- **Automated Validation**: All PRs validated automatically
- **Environment Gates**: Approval required for stg/prod
- **Audit Trail**: All changes tracked in Git history

## Quick Start Guide

### Prerequisites

```bash
# Install required tools
brew install terraform awscli kubectl

# Or use package managers for Linux
sudo apt-get install terraform awscli kubectl

# Install Python dependencies
pip install -r src/scripts/requirements.txt

# Configure AWS credentials
aws configure
```

### Local Development

```bash
# Navigate to Kubernetes infrastructure
cd src/terraform/kubernetes

# Initialize Terraform
terraform init

# Review and customize environment configuration
vim environments/dev/terraform.tfvars

# Plan deployment
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply configuration (creates EKS cluster)
terraform apply -var-file=environments/dev/terraform.tfvars

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Verify cluster
kubectl get nodes
kubectl get namespaces
```

### Using GitHub Actions

1. **Configure Secrets** (Settings → Secrets and variables → Actions)
   - Add `AWS_ACCESS_KEY_ID`
   - Add `AWS_SECRET_ACCESS_KEY`

2. **Set up Environments** (Settings → Environments)
   - Create `dev`, `stg`, `prod` environments
   - Add protection rules (approvals for stg/prod)

3. **Trigger Deployment**
   - Go to Actions → EKS Terraform CI/CD
   - Click "Run workflow"
   - Select environment and action (plan/apply/destroy)
   - Click "Run workflow"

4. **Monitor Progress**
   - Watch workflow execution in real-time
   - Review plan outputs before approval
   - Check deployment logs and audit results

## Environment Configurations

### Development (dev)

**Purpose**: Development and testing

- **Resources**: Minimal (1-2 nodes)
- **Instance Types**: t3.small
- **NAT Gateway**: Disabled (cost savings)
- **Logging**: Basic (api, audit, authenticator)
- **Auto-shutdown**: Enabled

### Staging (stg)

**Purpose**: Pre-production testing and validation

- **Resources**: Medium (2-4 nodes)
- **Instance Types**: t3.medium
- **Node Groups**: General + Spot instances
- **NAT Gateway**: Enabled
- **Logging**: Full (all log types)

### Production (prod)

**Purpose**: Production workloads

- **Resources**: High availability (3+ nodes across 3 AZs)
- **Instance Types**: t3.medium to t3.large
- **Node Groups**:
  - Critical (on-demand, taints for critical workloads)
  - General (on-demand, standard workloads)
  - Batch (spot instances, cost-optimized)
- **NAT Gateway**: Enabled (required)
- **Logging**: Full with extended retention (30 days)
- **Monitoring**: Enhanced monitoring enabled

## Verification Commands

### Cluster Health

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Check cluster info
kubectl cluster-info

# List all nodes
kubectl get nodes -o wide

# Check node status and labels
kubectl describe nodes

# View system pods
kubectl get pods -n kube-system

# Check cluster version
kubectl version
```

### Network Verification

```bash
# List services
kubectl get svc --all-namespaces

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check endpoints
kubectl get endpoints --all-namespaces
```

### Security Verification

```bash
# List RBAC roles
kubectl get roles,rolebindings --all-namespaces

# Check service accounts
kubectl get sa --all-namespaces

# Verify network policies
kubectl get networkpolicies --all-namespaces

# Check pod security policies
kubectl get psp
```

### Resource Verification

```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# View resource quotas
kubectl get resourcequotas --all-namespaces

# Check limit ranges
kubectl get limitranges --all-namespaces
```

### Using Cluster Audit Script

```bash
cd src/scripts

# Run comprehensive audit
python cluster_audit.py --environment dev

# View audit results
cat ../output/cluster-audit-*.json | jq .

# Run specific checks
python cluster_audit.py --environment dev --region us-east-1
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Terraform Initialization Fails

**Problem**: `terraform init` fails with backend errors

**Solution**:
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### 2. Node Group Not Scaling

**Problem**: Nodes not joining cluster or not scaling

**Solution**:
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name eks-platform-dev --nodegroup-name general

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name>

# View cluster events
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

#### 3. Cannot Connect to Cluster

**Problem**: `kubectl` commands fail with connection errors

**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Check AWS credentials
aws sts get-caller-identity

# Verify context
kubectl config current-context
kubectl config get-contexts
```

#### 4. Pods Stuck in Pending

**Problem**: Pods remain in Pending state

**Solution**:
```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes

# Check for resource quotas
kubectl get resourcequotas -n <namespace>

# Enable cluster autoscaler if needed
```

#### 5. GitHub Actions Workflow Fails

**Problem**: CI/CD pipeline fails

**Solution**:
```bash
# Check secrets are configured
# Settings → Secrets and variables → Actions

# Verify AWS credentials have required permissions
aws sts get-caller-identity

# Review workflow logs for specific errors

# Test Terraform locally first
terraform plan -var-file=environments/dev/terraform.tfvars
```

## Design Decisions & Assumptions

### Design Decisions

1. **Local Backend for Testing**
   - Assumption: For demo/testing purposes
   - Production should use S3 backend with state locking

2. **Mock Credentials Option**
   - Allows testing without AWS account
   - Disabled by default in production

3. **Multi-AZ Deployment**
   - High availability across 3 availability zones
   - Increased cost but better resilience

4. **Separate Node Groups**
   - Different node groups for different workload types
   - Allows for cost optimization with spot instances

5. **Full Logging Enabled**
   - All control plane logs enabled
   - Essential for troubleshooting and compliance

### Assumptions

1. **AWS Region**: us-east-1 (configurable per environment)
2. **Kubernetes Version**: 1.28 (latest stable at time of writing)
3. **VPC CIDR**: Non-overlapping CIDRs per environment
4. **GitHub Hosted Runners**: Using GitHub-hosted runners for CI/CD
5. **ECR for Container Images**: Amazon ECR for storing container images

## Best Practices Implemented

### Security
- ✅ Private subnets for worker nodes
- ✅ Security groups with minimal required access
- ✅ IAM roles with least privilege
- ✅ IRSA support for pod-level permissions
- ✅ Encrypted communication (TLS for API server)

### Reliability
- ✅ Multi-AZ deployment
- ✅ Auto-scaling node groups
- ✅ Health checks and monitoring
- ✅ Comprehensive logging

### Cost Optimization
- ✅ Spot instances for non-critical workloads
- ✅ Right-sized instances per environment
- ✅ NAT Gateway optional for dev
- ✅ Auto-scaling to prevent over-provisioning

### Operational Excellence
- ✅ Infrastructure as Code (versioned, reviewable)
- ✅ Automated CI/CD pipeline
- ✅ Comprehensive documentation
- ✅ Audit trail via Git history
- ✅ Automated testing and validation





