# Root Kubernetes Infrastructure Module
# This module orchestrates EKS cluster deployment across multiple environments

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Local backend for testing
  # In production, replace with S3 backend or other remote backend
  backend "local" {
    path = "terraform.tfstate"
  }
}

# AWS Provider configuration with mock credentials for testing
provider "aws" {
  region = var.aws_region

  # For local testing without real AWS credentials
  skip_credentials_validation = var.skip_aws_validation
  skip_requesting_account_id  = var.skip_aws_validation
  skip_metadata_api_check     = var.skip_aws_validation
  s3_force_path_style         = var.skip_aws_validation

  # Mock credentials for testing (DO NOT use in production)
  access_key = var.skip_aws_validation ? "mock_access_key" : null
  secret_key = var.skip_aws_validation ? "mock_secret_key" : null

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Owner       = var.owner
    }
  }
}

# Kubernetes provider - configured after EKS cluster is created
provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks_cluster.cluster_id,
      "--region",
      var.aws_region
    ]
  }
}

# EKS Cluster Module
module "eks_cluster" {
  source = "./modules/eks-cluster"

  cluster_name       = "${var.project_name}-${var.environment}"
  kubernetes_version = var.kubernetes_version

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs
  allowed_cidr_blocks     = var.allowed_cidr_blocks

  cluster_log_types = var.cluster_log_types

  node_groups = var.node_groups

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# OIDC Provider for IAM Roles for Service Accounts (IRSA)
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = module.eks_cluster.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = module.eks_cluster.cluster_oidc_issuer_url

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-irsa"
      Environment = var.environment
    }
  )
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count             = var.enable_cluster_logging ? 1 : 0
  name              = "/aws/eks/${var.project_name}-${var.environment}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs"
      Environment = var.environment
    }
  )
}
