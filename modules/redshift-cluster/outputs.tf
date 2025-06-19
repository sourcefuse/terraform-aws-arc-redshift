output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  description = "The ARN of the Redshift cluster"
  value       = aws_redshift_cluster.this.arn
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = "${aws_redshift_cluster.this.endpoint}:${aws_redshift_cluster.this.port}"
}

output "redshift_cluster_hostname" {
  description = "The hostname of the Redshift cluster"
  value       = aws_redshift_cluster.this.endpoint
}

output "redshift_cluster_port" {
  description = "The port of the Redshift cluster"
  value       = aws_redshift_cluster.this.port
}

output "redshift_cluster_database_name" {
  description = "The name of the default database in the Redshift cluster"
  value       = aws_redshift_cluster.this.database_name
}

output "redshift_security_group_id" {
  description = "The ID of the security group associated with the Redshift cluster"
  value       = length(aws_security_group.this) > 0 ? aws_security_group.this[0].id : null
}

output "redshift_subnet_group_id" {
  description = "The ID of the Redshift subnet group"
  value       = length(aws_redshift_subnet_group.this) > 0 ? aws_redshift_subnet_group.this[0].id : null
}
