output "aws_account_id" {
  description = "AWS Account ID integrated with Datadog"
  value       = data.aws_caller_identity.current.account_id
}

output "datadog_role_arn" {
  description = "ARN of the IAM role for Datadog integration"
  value       = aws_iam_role.datadog_integration.arn
}

output "datadog_role_name" {
  description = "Name of the IAM role for Datadog integration"
  value       = aws_iam_role.datadog_integration.name
}
