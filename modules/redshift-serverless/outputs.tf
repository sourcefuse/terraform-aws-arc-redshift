output "redshift_serverless_namespace_id" {
  description = "Redshift Serverless namespace ID"
  value = var.manage_admin_password ? aws_redshiftserverless_namespace.managed[0].id : aws_redshiftserverless_namespace.custom[0].id
}

output "redshift_serverless_namespace_arn" {
  description = "Redshift Serverless namespace ARN"
  value = var.manage_admin_password ? aws_redshiftserverless_namespace.managed[0].arn : aws_redshiftserverless_namespace.custom[0].arn
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

