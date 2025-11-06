variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "datadog_external_id" {
  description = "Datadog AWS external ID for secure role assumption"
  type        = string
  sensitive   = true
  default     = ""
}
