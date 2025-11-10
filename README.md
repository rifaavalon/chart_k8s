# EKS Kubernetes Infrastructure

Production-ready Terraform infrastructure for deploying Amazon EKS clusters across multiple environments (dev, stg, prod).

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Module Structure](#module-structure)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Verification](#verification)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This Terraform module provides:

- **Production-ready EKS clusters** with configurable node groups
- **Multi-environment support** (dev, stg, prod) with environment-specific configurations
- **VPC networking** with public and private subnets across multiple AZs
- **IAM roles and policies** for cluster and node groups
- **Security groups** with appropriate ingress/egress rules
- **Cluster logging and monitoring** via CloudWatch
- **IRSA support** (IAM Roles for Service Accounts)
- **Auto-scaling node groups** with configurable sizing
- **Support for both On-Demand and Spot instances**

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Account                          │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.x.0.0/16)                   │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │   Public     │  │   Public     │  │   Public     │ │ │
│  │  │   Subnet     │  │   Subnet     │  │   Subnet     │ │ │
│  │  │   AZ-1       │  │   AZ-2       │  │   AZ-3       │ │ │
│  │  │              │  │              │  │              │ │ │
│  │  │  NAT GW      │  │  NAT GW      │  │  NAT GW      │ │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │ │
│  │         │                 │                 │         │ │
│  │  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐ │ │
│  │  │   Private    │  │   Private    │  │   Private    │ │ │
│  │  │   Subnet     │  │   Subnet     │  │   Subnet     │ │ │
│  │  │   AZ-1       │  │   AZ-2       │  │   AZ-3       │ │ │
│  │  │              │  │              │  │              │ │ │
│  │  │  EKS Nodes   │  │  EKS Nodes   │  │  EKS Nodes   │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  │                                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               EKS Control Plane                        │ │
│  │           (Managed by AWS)                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **VPC** | Isolated network with CIDR blocks per environment |
| **Public Subnets** | Internet-facing subnets for NAT gateways and load balancers |
| **Private Subnets** | Internal subnets for EKS worker nodes |
| **NAT Gateways** | Enable internet access for private subnets |
| **EKS Control Plane** | Managed Kubernetes control plane |
| **Node Groups** | Auto-scaling groups of worker nodes |
| **Security Groups** | Network access controls for cluster and nodes |
| **IAM Roles** | Identity and access management for cluster and pods |
| **CloudWatch** | Centralized logging and monitoring |

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.0 | Infrastructure provisioning |
| **AWS CLI** | >= 2.0 | AWS interaction |
| **kubectl** | >= 1.27 | Kubernetes cluster management |
| **Python** | >= 3.8 | Cluster audit script |

#### Installation Commands

```bash
# Terraform
brew install terraform
# or
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# AWS CLI
brew install awscli
# or
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# kubectl
brew install kubectl
# or
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Python dependencies
pip install -r ../../scripts/requirements.txt
```

### Required AWS Permissions

Your AWS credentials need permissions to create:
- VPC, Subnets, Route Tables, Internet Gateways, NAT Gateways
- EKS Clusters and Node Groups
- EC2 Instances, Security Groups, Elastic IPs
- IAM Roles and Policies
- CloudWatch Log Groups
- ECR Repositories (for container images)

### AWS Credentials Setup

```bash
# Configure AWS credentials
aws configure

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd chart_k8s/src/terraform/kubernetes
```

### 2. Review Configuration

Edit the environment-specific tfvars file:

```bash
# For development
vim environments/dev/terraform.tfvars

# For staging
vim environments/stg/terraform.tfvars

# For production
vim environments/prod/terraform.tfvars
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
# Plan for development
terraform plan -var-file=environments/dev/terraform.tfvars

# Plan for staging
terraform plan -var-file=environments/stg/terraform.tfvars

# Plan for production
terraform plan -var-file=environments/prod/terraform.tfvars
```

### 5. Apply Configuration

```bash
# Deploy to development
terraform apply -var-file=environments/dev/terraform.tfvars

# Deploy to staging
terraform apply -var-file=environments/stg/terraform.tfvars

# Deploy to production (requires approval)
terraform apply -var-file=environments/prod/terraform.tfvars
```

### 6. Configure kubectl

```bash
# Update kubeconfig for the new cluster
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

## Module Structure

```
.
├── main.tf                      # Root module orchestration
├── variables.tf                 # Input variable definitions
├── outputs.tf                   # Output value definitions
├── README.md                    # This file
├── environments/                # Environment-specific configurations
│   ├── dev/
│   │   └── terraform.tfvars    # Development variables
│   ├── stg/
│   │   └── terraform.tfvars    # Staging variables
│   └── prod/
│       └── terraform.tfvars    # Production variables
└── modules/
    └── eks-cluster/            # Reusable EKS cluster module
        ├── main.tf             # EKS cluster resources
        ├── variables.tf        # Module input variables
        ├── outputs.tf          # Module outputs
        └── templates/
            └── aws-auth-cm.yaml.tpl  # AWS auth ConfigMap template
```

## Configuration

### Environment-Specific Settings

#### Development (dev)

- **Purpose**: Testing and development
- **Cost Optimization**: NAT Gateway disabled, small instances
- **Node Configuration**:
  - 1-2 nodes
  - t3.small instances
  - On-demand capacity

#### Staging (stg)

- **Purpose**: Pre-production testing
- **Configuration**:
  - 2-4 nodes
  - Mix of on-demand and spot instances
  - Full logging enabled

#### Production (prod)

- **Purpose**: Production workloads
- **High Availability**:
  - Minimum 3 nodes across 3 AZs
  - Multiple node groups for different workload types
  - Enhanced monitoring and logging
- **Node Groups**:
  - **critical**: On-demand, for critical services
  - **general**: On-demand, for standard workloads
  - **batch**: Spot instances, for batch processing

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | Name of the EKS cluster | `eks-platform-{env}` |
| `kubernetes_version` | Kubernetes version | `1.28` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `enable_nat_gateway` | Enable NAT Gateway | `true` |
| `node_groups` | Map of node group configurations | See tfvars |
| `cluster_log_types` | Control plane log types | `["api", "audit", ...]` |

## Deployment

### Using Terraform Directly

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file=environments/{env}/terraform.tfvars -out=plan.tfplan

# Apply
terraform apply plan.tfplan

# Destroy
terraform destroy -var-file=environments/{env}/terraform.tfvars
```

### Using GitHub Actions (Recommended)

The repository includes automated CI/CD pipelines:

#### Automatic Workflows

- **Pull Request**: Automatic validation and planning
- **Push to main**: Triggers validation and testing

#### Manual Deployment

1. Go to Actions → EKS Terraform CI/CD
2. Click "Run workflow"
3. Select:
   - **Environment**: dev, stg, or prod
   - **Action**: plan, apply, or destroy
4. Click "Run workflow"

## Verification

### Cluster Verification Commands

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes -o wide

# Check node labels
kubectl get nodes --show-labels

# Verify node groups
aws eks list-nodegroups --cluster-name eks-platform-dev

# Describe node group
aws eks describe-nodegroup \
  --cluster-name eks-platform-dev \
  --nodegroup-name general

# Check cluster version
kubectl version --short

# Verify namespaces
kubectl get namespaces

# Check system pods
kubectl get pods -n kube-system

# View cluster endpoints
kubectl config view

# Test cluster connectivity
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods
kubectl delete pod test-pod
```

### Node Health Checks

```bash
# Check node status
kubectl get nodes

# Get detailed node information
kubectl describe node <node-name>

# Check node resource usage
kubectl top nodes

# View node events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Networking Verification

```bash
# Check services
kubectl get services --all-namespaces

# Verify DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Test pod-to-pod communication
kubectl run test1 --image=nginx
kubectl run test2 --image=busybox --rm -it --restart=Never -- wget -O- http://test1
```

### Security Verification

```bash
# Check RBAC
kubectl get roles,rolebindings --all-namespaces
kubectl get clusterroles,clusterrolebindings

# Verify service accounts
kubectl get serviceaccounts --all-namespaces

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:kubernetes.io/cluster/eks-platform-dev,Values=owned"

# Verify IAM roles
aws iam list-roles | grep eks-platform
```

### Using the Cluster Audit Script

```bash
# Run audit for development
python ../../scripts/cluster_audit.py --environment dev

# Run audit for staging
python ../../scripts/cluster_audit.py --environment stg

# Run audit for production
python ../../scripts/cluster_audit.py --environment prod --region us-east-1

# Run audit without saving to file
python ../../scripts/cluster_audit.py --environment dev --no-save
```

## CI/CD Pipeline

### Pipeline Stages

1. **Validate**
   - Terraform format check
   - Terraform validation
   - Security scanning (Bandit)

2. **Test**
   - Terraform plan for all environments
   - Plan results uploaded as artifacts

3. **Infrastructure** (Manual trigger)
   - Terraform apply
   - Terraform destroy

4. **Deploy** (After successful apply)
   - Build and push container image
   - Deploy to Kubernetes
   - Run cluster audit

### GitHub Secrets Required

Configure these secrets in GitHub Settings → Secrets:

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### GitHub Environments

Configure these environments with protection rules:

- **dev**: Auto-deploy on push
- **stg**: Requires 1 approval
- **prod**: Requires 2 approvals, protected branches

## Troubleshooting

### Common Issues

#### 1. Terraform Init Fails

```bash
# Error: Failed to initialize backend
# Solution: Remove .terraform directory and try again
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### 2. AWS Authentication Errors

```bash
# Error: No valid credential sources found
# Solution: Configure AWS credentials
aws configure

# Or check environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
```

#### 3. kubectl Cannot Connect to Cluster

```bash
# Error: Unable to connect to the server
# Solution: Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

# Verify context
kubectl config current-context
kubectl config get-contexts
```

#### 4. Nodes Not Joining Cluster

```bash
# Check node group status
aws eks describe-nodegroup --cluster-name eks-platform-dev --nodegroup-name general

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups

# View node events
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

#### 5. Resource Quota Errors

```bash
# Error: Insufficient capacity
# Solution: Check AWS service quotas
aws service-quotas list-service-quotas --service-code ec2

# Request quota increase if needed
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 20
```

#### 6. Network Connectivity Issues

```bash
# Check security groups
kubectl get nodes -o jsonpath='{.items[*].spec.providerID}' | xargs -n1 aws ec2 describe-instances --instance-ids

# Verify VPC DNS
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsHostnames
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsSupport
```

### Debugging Tips

```bash
# Enable detailed Terraform logging
export TF_LOG=DEBUG
terraform apply -var-file=environments/dev/terraform.tfvars

# Check CloudWatch logs
aws logs tail /aws/eks/eks-platform-dev/cluster --follow

# View pod logs
kubectl logs -n kube-system <pod-name>

# Execute into pod for debugging
kubectl exec -it <pod-name> -- /bin/bash

# Check kubelet logs on nodes (if SSH access available)
journalctl -u kubelet -f
```

## Best Practices

### Security

1. **Principle of Least Privilege**: Grant minimal IAM permissions
2. **Network Policies**: Implement network policies for pod-to-pod communication
3. **Private Endpoints**: Use private endpoints in production
4. **Secrets Management**: Use AWS Secrets Manager or External Secrets Operator
5. **IRSA**: Use IAM Roles for Service Accounts instead of instance profiles

### High Availability

1. **Multi-AZ Deployment**: Spread nodes across multiple availability zones
2. **Pod Disruption Budgets**: Define PDBs for critical workloads
3. **Auto-scaling**: Configure horizontal and cluster autoscaling
4. **Health Checks**: Implement liveness and readiness probes

### Cost Optimization

1. **Right-sizing**: Monitor and adjust node sizes
2. **Spot Instances**: Use spot instances for non-critical workloads
3. **Auto-scaling**: Enable cluster autoscaler to scale down unused capacity
4. **Resource Limits**: Set resource requests and limits on pods

### Operational Excellence

1. **Monitoring**: Enable all control plane logs
2. **Metrics**: Use CloudWatch Container Insights
3. **Alerting**: Set up alerts for critical metrics
4. **Backup**: Regular etcd backups (managed by AWS for EKS)
5. **Updates**: Keep Kubernetes version up to date

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

## Support

For issues and questions:
- Create an issue in the repository
- Contact: DL-DPDATA-DataScience-ML-Ops@charter.com

---

**Generated with Terraform and configured for production-ready EKS deployments**
