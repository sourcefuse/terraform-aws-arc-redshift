output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = module.redshift.redshift_cluster_id
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = module.redshift.redshift_cluster_endpoint
}

output "redshift_endpoint" {
  description = "The endpoint of the Redshift deployment (either cluster or serverless)"
  value       = module.redshift.redshift_endpoint
}
