output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  description = "The ARN of the Redshift cluster"
  value       = aws_redshift_cluster.this.arn
}
output "redshift_cluster_namespace_arn" {
  description = "The ARN of the Redshift cluster"
  value       = aws_redshift_cluster.this.cluster_namespace_arn
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
