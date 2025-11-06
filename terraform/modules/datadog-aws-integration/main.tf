# Datadog AWS Integration
# This creates the IAM role that Datadog uses to collect metrics from AWS

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM Role for Datadog AWS Integration
resource "aws_iam_role" "datadog_integration" {
  name = "${var.environment}-datadog-aws-integration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::464622532012:root"  # Datadog AWS Account
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.datadog_external_id
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for Datadog integration
resource "aws_iam_role_policy_attachment" "datadog_integration" {
  role       = aws_iam_role.datadog_integration.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Additional permissions for RDS, ECS, and other services
resource "aws_iam_role_policy" "datadog_integration_additional" {
  name = "${var.environment}-datadog-additional-permissions"
  role = aws_iam_role.datadog_integration.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "ec2:Describe*",
          "support:*",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:Describe*",
          "rds:List*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:Describe*",
          "ecs:List*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Configure Datadog AWS Integration (using new resource)
resource "datadog_integration_aws_account" "main" {
  account_id = data.aws_caller_identity.current.account_id

  aws_regions {
    include_all = true
  }

  auth_config {
    role_name = aws_iam_role.datadog_integration.name
  }

  aws_account_tags = ["env:${var.environment}", "managed:terraform"]

  metrics_config {
    enabled = true

    namespace_filters {
      exclude_only = []
      include_only = [
        "AWS/EC2",
        "AWS/ECS",
        "AWS/RDS",
        "AWS/ELB",
        "AWS/ApplicationELB",
        "AWS/Lambda",
        "AWS/AutoScaling"
      ]
    }
  }

  resources_config {
    cloud_security_posture_management_collection = false
    extended_collection                           = true
  }

  traces_config {
    xray_services {
      include_all = false
    }
  }

  depends_on = [
    aws_iam_role.datadog_integration,
    aws_iam_role_policy_attachment.datadog_integration,
    aws_iam_role_policy.datadog_integration_additional
  ]
}
