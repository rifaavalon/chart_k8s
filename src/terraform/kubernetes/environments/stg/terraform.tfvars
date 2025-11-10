# Staging Environment Configuration

environment    = "stg"
aws_region     = "us-east-1"
project_name   = "eks-platform"
owner          = "platform-team"

# For production-like environments, set this to false and use real AWS credentials
skip_aws_validation = true

# Kubernetes Configuration
kubernetes_version = "1.28"

# Network Configuration
vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24",
  "10.1.3.0/24"
]
private_subnet_cidrs = [
  "10.1.10.0/24",
  "10.1.11.0/24",
  "10.1.12.0/24"
]

# Enable NAT gateway for staging
enable_nat_gateway = true

# Cluster Access
endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["0.0.0.0/0"]

# Logging - All log types for staging
cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
enable_cluster_logging = true
log_retention_days     = 14

# IRSA (IAM Roles for Service Accounts)
enable_irsa = true

# Node Groups - Medium configuration for staging
node_groups = {
  general = {
    instance_types  = ["t3.medium"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 30
    desired_size    = 2
    max_size        = 4
    min_size        = 2
    max_unavailable = 1
    labels = {
      role        = "general"
      environment = "stg"
    }
    taints = []
    tags = {
      Team = "platform"
    }
  }

  spot = {
    instance_types  = ["t3.medium", "t3a.medium"]
    capacity_type   = "SPOT"
    disk_size       = 30
    desired_size    = 1
    max_size        = 3
    min_size        = 0
    max_unavailable = 1
    labels = {
      role        = "spot"
      environment = "stg"
    }
    taints = [{
      key    = "spot"
      value  = "true"
      effect = "NoSchedule"
    }]
    tags = {
      Team = "platform"
      Type = "spot"
    }
  }
}

# Additional Tags
tags = {
  CostCenter = "staging"
  Team       = "platform"
  Terraform  = "true"
  Purpose    = "pre-production-testing"
}
