variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "owner" {
  description = "Resource owner/team name"
  type        = string
  default     = "Implementation Services"
}

variable "datadog_api_key" {
  description = "Datadog API key (sensitive)"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key (sensitive) - required for creating monitors/dashboards"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Datadog site (datadoghq.com, datadoghq.eu, etc.)"
  type        = string
  default     = "us5.datadoghq.com"
}

variable "db_password" {
  description = "RDS database password (sensitive) - only needed when RDS module is enabled"
  type        = string
  sensitive   = true
  default     = "placeholder"  # Set via GitHub Secret when enabling RDS module
}

variable "datadog_external_id" {
  description = "Datadog AWS External ID for secure role assumption (optional - auto-generated if not provided)"
  type        = string
  sensitive   = true
  default     = ""
}
