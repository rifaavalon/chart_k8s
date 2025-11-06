variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key"
  type        = string
  sensitive   = true
}

variable "enable_ecs_monitoring" {
  description = "Enable ECS-specific Datadog monitors"
  type        = bool
  default     = false
}

variable "enable_rds_monitoring" {
  description = "Enable RDS-specific Datadog monitors"
  type        = bool
  default     = false
}
