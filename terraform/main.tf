terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
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

provider "datadog" {
  api_key  = var.datadog_api_key
  app_key  = var.datadog_app_key
  api_url  = "https://api.us5.datadoghq.com/"  # US5 site
  validate = false  # Allow provider to be configured without validating credentials during plan
}

module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "compute" {
  source = "./modules/compute"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  key_name          = var.key_name
  datadog_api_key    = var.datadog_api_key
  datadog_site       = var.datadog_site
}

module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_ids      = module.compute.instance_ids
}

## UNCOMMENT FOR DEMO: ECS + RDS with Datadog Monitoring
## Before uncommenting, add these GitHub Secrets:
## - DD_APP_KEY (already added)
## - DB_PASSWORD (add tomorrow morning)


# ECS Service with Datadog sidecar
module "ecs" {
  source = "./modules/ecs"

  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  alb_security_group_id   = module.alb.alb_security_group_id
  alb_listener_arn        = module.alb.alb_listener_arn
  datadog_api_key         = var.datadog_api_key
  datadog_site            = var.datadog_site
  aws_region              = var.aws_region
}

# RDS PostgreSQL Database
module "rds" {
  source = "./modules/rds"

  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_id  = module.ecs.security_group_id
  db_password            = var.db_password
}

# Datadog AWS Integration (for RDS, ECS CloudWatch metrics)
# COMMENTED OUT - Configure manually in Datadog UI
# module "datadog_aws_integration" {
#   source = "./modules/datadog-aws-integration"
#
#   environment          = var.environment
#   datadog_external_id  = var.datadog_external_id
# }

module "datadog" {
  source = "./modules/datadog"

  environment           = var.environment
  datadog_api_key       = var.datadog_api_key
  datadog_app_key       = var.datadog_app_key
  enable_ecs_monitoring = true  # Change to true when uncommenting ECS module
  enable_rds_monitoring = true  # Change to true when uncommenting RDS module
}
