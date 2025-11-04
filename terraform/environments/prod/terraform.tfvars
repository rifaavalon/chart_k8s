environment = "prod"
aws_region  = "us-east-1"

vpc_cidr           = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

instance_count = 10
instance_type  = "t3.xlarge"
key_name       = "datadog-demo-key"

datadog_site = "datadoghq.com"

# Note: datadog_api_key should be set via environment variable:
# export TF_VAR_datadog_api_key="your-api-key"
