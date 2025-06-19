output "redshift_serverless_namespace_id" {
  description = "The ID of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.this.id
}

output "redshift_serverless_namespace_arn" {
  description = "The ARN of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.this.arn
}

output "redshift_serverless_workgroup_id" {
  description = "The ID of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.this.id
}

output "redshift_serverless_workgroup_arn" {
  description = "The ARN of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.this.arn
}

output "redshift_serverless_endpoint" {
  description = "The endpoint URL for the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.this.endpoint
}

output "redshift_serverless_security_group_id" {
  description = "The ID of the security group associated with the Redshift Serverless workgroup"
  value       = length(aws_security_group.this) > 0 ? aws_security_group.this[0].id : null
}
