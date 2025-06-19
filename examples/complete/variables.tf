variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for the resources"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name for the Redshift cluster"
  type        = string
  default     = "analytics"
}

# Redshift Configuration
variable "database_name" {
  description = "Name of the database to create in the Redshift cluster"
  type        = string
  default     = "analytics"
}

variable "master_username" {
  description = "Username for the master user"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Password for the master DB user. If null, a random password will be generated"
  type        = string
  sensitive   = true
  default     = null
}

variable "manage_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = null
}

variable "project_name" {
  description = "Name of the project for tagging"
  type        = string
  default     = "data-platform"
}

variable "node_type" {
  description = "Node type for the Redshift cluster"
  type        = string
  default     = "dc2.large"
}

variable "node_count" {
  description = "Number of nodes in the Redshift cluster"
  type        = number
  default     = 1
}

# Feature Flags - Core Features
variable "enable_serverless" {
  description = "Whether to enable Redshift Serverless. If true, creates the serverless module; if false, creates the standard cluster module."
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Whether to enable encryption at rest for the Redshift cluster"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to enable logging to S3 for the Redshift cluster"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Whether to enable CloudWatch monitoring and alerts"
  type        = bool
  default     = true
}

variable "enable_maintenance" {
  description = "Whether to enable automated maintenance via Lambda"
  type        = bool
  default     = true
}

# Feature Flags - Integrations
variable "enable_s3_integration" {
  description = "Whether to enable S3 integration for data loading"
  type        = bool
  default     = true
}

# S3 Event Integration removed - will be implemented later
variable "enable_s3_event_integration" {
  description = "Whether to enable S3 event notifications to trigger Lambda for data loading"
  type        = bool
  default     = false
}
#   type        = bool
#   default     = false
# }

variable "enable_zero_etl" {
  description = "Whether to enable Zero-ETL integration"
  type        = bool
  default     = false
}

# S3 Event Integration Configuration
variable "s3_filter_prefix" {
  description = "Prefix filter for S3 event notifications"
  type        = string
  default     = "data/"
}

variable "s3_filter_suffix" {
  description = "Suffix filter for S3 event notifications"
  type        = string
  default     = ".csv"
}

variable "redshift_target_table" {
  description = "Name of the target table in Redshift for data loading"
  type        = string
  default     = "public.events"
}

# Zero-ETL Configuration
variable "zero_etl_source_arn" {
  description = "ARN of the source database for Zero-ETL integration"
  type        = string
  default     = ""
}

variable "tables_included" {
  description = "List of tables to include in the Zero-ETL integration"
  type        = list(string)
  default     = []
}

variable "tables_excluded" {
  description = "List of tables to exclude from the Zero-ETL integration"
  type        = list(string)
  default     = []
}

# Serverless specific settings
variable "base_capacity" {
  description = "The base data warehouse capacity in Redshift Processing Units (RPUs)"
  type        = number
  default     = 32
}

variable "max_capacity" {
  description = "The maximum data warehouse capacity in Redshift Processing Units (RPUs)"
  type        = number
  default     = 128
}

variable "namespace_name" {
  description = "The name of the Redshift Serverless namespace"
  type        = string
  default     = null
}

variable "workgroup_name" {
  description = "The name of the Redshift Serverless workgroup"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Data Platform"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
variable "automated_snapshot_retention_period" {
  description = "The number of days to keep automated snapshots"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Determines whether a final snapshot of the cluster is created before Redshift deletes it"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "If true, the cluster can be accessed from a public network"
  type        = bool
  default     = false
}
