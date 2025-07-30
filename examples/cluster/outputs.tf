output "cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = module.redshift.cluster_id
}

output "cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = module.redshift.cluster_endpoint
}

output "endpoint" {
  description = "The endpoint of the Redshift deployment (either cluster or serverless)"
  value       = module.redshift.endpoint
}
