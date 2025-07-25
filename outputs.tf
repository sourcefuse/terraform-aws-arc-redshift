###############################################################################
####################     outputs   ###########################################
###############################################################################

# Conditional outputs for standard Redshift cluster
output "redshift_cluster_id" {
  description = "The ID of the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_id, null)
}

output "redshift_cluster_arn" {
  description = "The ARN of the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_arn, null)
}
output "redshift_cluster_namespace_arn" {
  description = "The ARN of the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_namespace_arn, null)
}

output "redshift_cluster_endpoint" {
  description = "The connection endpoint for the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_endpoint, null)
}

output "redshift_cluster_hostname" {
  description = "The hostname of the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_hostname, null)
}

output "redshift_cluster_port" {
  description = "The port of the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_port, null)
}

output "redshift_cluster_database_name" {
  description = "The name of the default database in the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_cluster_database_name, null)
}

output "redshift_cluster_security_group_id" {
  description = "The ID of the security group associated with the Redshift cluster"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_security_group_id, null)
}

output "redshift_subnet_group_id" {
  description = "The ID of the Redshift subnet group"
  value       = var.enable_serverless ? null : try(module.redshift_cluster[0].redshift_subnet_group_id, null)
}

# Conditional outputs for Redshift Serverless
output "redshift_serverless_namespace_id" {
  description = "The ID of the Redshift Serverless namespace"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_namespace_id, null) : null
}

output "redshift_serverless_namespace_arn" {
  description = "The ARN of the Redshift Serverless namespace"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_namespace_arn, null) : null
}

output "redshift_serverless_workgroup_id" {
  description = "The ID of the Redshift Serverless workgroup"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_workgroup_id, null) : null
}

output "redshift_serverless_workgroup_arn" {
  description = "The ARN of the Redshift Serverless workgroup"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_workgroup_arn, null) : null
}

output "redshift_serverless_endpoint" {
  description = "The endpoint URL for the Redshift Serverless workgroup"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_endpoint, null) : null
}

# Common outputs
output "redshift_endpoint" {
  description = "The endpoint of the Redshift deployment (either cluster or serverless)"
  value       = var.enable_serverless ? try(module.redshift_serverless[0].redshift_serverless_endpoint, null) : try(module.redshift_cluster[0].redshift_cluster_endpoint, null)
}

output "redshift_database_name" {
  description = "The name of the database in the Redshift deployment"
  value       = var.database_name
}

