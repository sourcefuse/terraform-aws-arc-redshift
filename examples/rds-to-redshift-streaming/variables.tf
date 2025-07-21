variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "namespace" {
  description = "Namespace for the infrastructure"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name of the RDS to Redshift streaming platform"
  type        = string
  default     = "rds-redshift-streaming"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "rds-redshift-streaming"
}

variable "vpc_name" {
  description = "Name of the VPC to use"
  type        = string
}

# RDS Configuration
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 1000
}

variable "source_database_name" {
  description = "Name of the source database"
  type        = string
  default     = "source_db"
}

variable "rds_master_username" {
  description = "RDS master username"
  type        = string
  default     = "postgres"
}

variable "rds_master_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

# DMS Configuration
variable "dms_instance_class" {
  description = "DMS replication instance class"
  type        = string
  default     = "dms.t3.medium"
}

variable "dms_allocated_storage" {
  description = "DMS allocated storage in GB"
  type        = number
  default     = 100
}

variable "dms_engine_version" {
  description = "DMS engine version"
  type        = string
  default     = "3.5.2"
}

variable "dms_multi_az" {
  description = "Enable Multi-AZ for DMS"
  type        = bool
  default     = false
}

variable "source_schema_name" {
  description = "Source schema name to replicate"
  type        = string
  default     = "public"
}

variable "target_schema_name" {
  description = "Target schema name in Redshift"
  type        = string
  default     = "replicated"
}

# Redshift Configuration
variable "enable_serverless" {
  description = "Enable Redshift Serverless instead of cluster"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the Redshift database"
  type        = string
  default     = "analytics_db"
}

variable "master_username" {
  description = "Master username for Redshift"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Master password for Redshift"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_user_password" {
  description = "Use AWS Secrets Manager for password management"
  type        = bool
  default     = false
}

variable "node_type" {
  description = "Node type for Redshift cluster"
  type        = string
  default     = "dc2.large"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "namespace_name" {
  description = "Name of the Redshift Serverless namespace"
  type        = string
  default     = "rds-streaming-namespace"
}

variable "workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  type        = string
  default     = "rds-streaming-workgroup"
}

variable "base_capacity" {
  description = "Base capacity for Redshift Serverless (RPUs)"
  type        = number
  default     = 32
}

variable "max_capacity" {
  description = "Maximum capacity for Redshift Serverless (RPUs)"
  type        = number
  default     = 512
}

# Other Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "automated_snapshot_retention_period" {
  description = "Number of days to retain automated snapshots"
  type        = number
  default     = 7
}
