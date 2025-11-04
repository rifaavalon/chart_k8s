bucket         = "datadog-demo-terraform-state"
key            = "datadog-agent/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "datadog-demo-terraform-locks"
encrypt        = true
