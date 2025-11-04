terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - can be overridden via -backend-config flags
  # For local development, comment this out or run: terraform init -backend=false
  backend "s3" {
    # These values can be overridden with -backend-config flags
    # Example: terraform init -backend-config="bucket=my-bucket"
    # Or use backend.hcl files per environment
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Datadog Agent Deployment"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# EC2 Instances Module
module "compute" {
  source = "./modules/compute"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  key_name          = var.key_name
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_ids      = module.compute.instance_ids
}
