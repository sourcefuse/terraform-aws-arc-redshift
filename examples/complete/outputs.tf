################################################################################
## Outputs
################################################################################

output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = module.redshift.redshift_cluster_id
  sensitive   = false
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = module.redshift.redshift_cluster_endpoint
  sensitive   = false
}

output "redshift_security_group_id" {
  description = "The ID of the security group associated with the Redshift cluster"
  value       = module.redshift.redshift_cluster_security_group_id
  sensitive   = false
}

output "master_password_ssm_parameter" {
  description = "The SSM parameter name where the master password is stored"
  value       = var.master_password != null ? aws_ssm_parameter.redshift_master_password[0].name : null
  sensitive   = true
}

output "redshift_master_password" {
  description = "The master password for the Redshift deployment (only if generated randomly)"
  value       = module.redshift.redshift_master_password
  sensitive   = true
}

output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = var.enable_encryption ? aws_kms_key.redshift[0].id : null
  sensitive   = false
}

output "logs_bucket_id" {
  description = "The ID of the S3 bucket used for logs"
  value       = var.enable_logging ? aws_s3_bucket.logs[0].id : null
  sensitive   = false
}

output "data_bucket_id" {
  description = "The ID of the S3 bucket used for data"
  value       = var.enable_s3_integration ? aws_s3_bucket.data[0].id : null
  sensitive   = false
}
