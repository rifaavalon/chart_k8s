variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for the load balancer"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Datadog site (e.g., us5.datadoghq.com)"
  type        = string
  default     = "us5.datadoghq.com"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
