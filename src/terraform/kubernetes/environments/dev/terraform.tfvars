# Development Environment Configuration

environment    = "dev"
aws_region     = "us-east-1"
project_name   = "eks-platform"
owner          = "platform-team"

# For local testing without AWS credentials, set this to true
skip_aws_validation = true

# Kubernetes Configuration
kubernetes_version = "1.28"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
private_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.11.0/24"
]

# Enable NAT gateway for dev (can be disabled to save costs in dev)
enable_nat_gateway = false

# Cluster Access
endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["0.0.0.0/0"]

# Logging
cluster_log_types = ["api", "audit", "authenticator"]
enable_cluster_logging = true
log_retention_days     = 7

# IRSA (IAM Roles for Service Accounts)
enable_irsa = true

# Node Groups - Small configuration for dev
node_groups = {
  general = {
    instance_types  = ["t3.small"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 20
    desired_size    = 1
    max_size        = 2
    min_size        = 1
    max_unavailable = 1
    labels = {
      role        = "general"
      environment = "dev"
    }
    taints = []
    tags = {
      Team = "platform"
    }
  }
}

# Additional Tags
tags = {
  CostCenter  = "development"
  Team        = "platform"
  Terraform   = "true"
  AutoShutoff = "true"
}
