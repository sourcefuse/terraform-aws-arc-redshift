
# RDS outputs
output "id" {
  value       = module.rds.id
  description = "Instance or Cluster ID"
}

output "identifier" {
  value       = module.rds.identifier
  description = "Instance or Cluster Identifier"
}

output "arn" {
  value       = module.rds.arn
  description = "Instance or Cluster ARN"
}


 # Redshift outputs
output "redshift_cluster_arn" {
  description = "The ARN of the Redshift cluster"
  value       = module.redshift.redshift_cluster_arn
}

