# Production Environment Configuration

environment    = "prod"
aws_region     = "us-east-1"
project_name   = "eks-platform"
owner          = "platform-team"

# For production, set this to false and use real AWS credentials
skip_aws_validation = false

# Kubernetes Configuration
kubernetes_version = "1.28"

# Network Configuration - Larger CIDR for production growth
vpc_cidr = "10.2.0.0/16"
public_subnet_cidrs = [
  "10.2.1.0/24",
  "10.2.2.0/24",
  "10.2.3.0/24"
]
private_subnet_cidrs = [
  "10.2.10.0/24",
  "10.2.11.0/24",
  "10.2.12.0/24"
]

# Enable NAT gateway for production (required)
enable_nat_gateway = true

# Cluster Access - More restrictive for production
endpoint_private_access = true
endpoint_public_access  = true
# In production, restrict this to your organization's CIDR blocks
public_access_cidrs = ["0.0.0.0/0"]

# Logging - All log types enabled for production
cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
enable_cluster_logging = true
log_retention_days     = 30

# IRSA (IAM Roles for Service Accounts)
enable_irsa = true

# Node Groups - Production configuration with multiple node groups
node_groups = {
  # Critical workloads - On-demand instances
  critical = {
    instance_types  = ["t3.large"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 50
    desired_size    = 3
    max_size        = 6
    min_size        = 3
    max_unavailable = 1
    labels = {
      role        = "critical"
      environment = "prod"
    }
    taints = [{
      key    = "critical"
      value  = "true"
      effect = "NoSchedule"
    }]
    tags = {
      Team     = "platform"
      Priority = "high"
    }
  }

  # General workloads - On-demand instances
  general = {
    instance_types  = ["t3.medium"]
    capacity_type   = "ON_DEMAND"
    disk_size       = 40
    desired_size    = 3
    max_size        = 8
    min_size        = 3
    max_unavailable = 1
    labels = {
      role        = "general"
      environment = "prod"
    }
    taints = []
    tags = {
      Team = "platform"
    }
  }

  # Batch processing - Spot instances for cost optimization
  batch = {
    instance_types  = ["t3.large", "t3a.large", "t2.large"]
    capacity_type   = "SPOT"
    disk_size       = 40
    desired_size    = 2
    max_size        = 10
    min_size        = 0
    max_unavailable = 2
    labels = {
      role        = "batch"
      environment = "prod"
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
  CostCenter    = "production"
  Team          = "platform"
  Terraform     = "true"
  Compliance    = "required"
  Backup        = "daily"
  AlertLevel    = "critical"
  BusinessUnit  = "engineering"
}
