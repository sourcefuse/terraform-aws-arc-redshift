################################################################################
## Outputs
################################################################################

output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = var.enable_encryption ? aws_kms_key.redshift[0].id : null
  sensitive   = false
}
output "serverless_namespace_id" {
  description = "The ID of the Redshift Serverless namespace"
  value       = module.redshift_serverless.redshift_serverless_namespace_id
}

output "serverless_namespace_arn" {
  description = "The ARN of the Redshift Serverless namespace"
  value       = module.redshift_serverless.redshift_serverless_namespace_arn
}

output "serverless_workgroup_arn" {
  description = "The ARN of the Redshift Serverless workgroup"
  value       = module.redshift_serverless.redshift_serverless_workgroup_arn
}
