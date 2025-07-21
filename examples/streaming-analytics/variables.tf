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
  description = "Name of the streaming analytics platform"
  type        = string
  default     = "streaming-analytics"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "streaming-analytics"
}

variable "vpc_name" {
  description = "Name of the VPC to use"
  type        = string
}

# Kinesis Configuration
variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis streams"
  type        = number
  default     = 2
}

variable "kinesis_retention_hours" {
  description = "Data retention period for Kinesis streams (hours)"
  type        = number
  default     = 24
}

variable "kinesis_stream_mode" {
  description = "Stream mode for Kinesis (PROVISIONED or ON_DEMAND)"
  type        = string
  default     = "PROVISIONED"
}

variable "enable_serverless" {
  description = "Enable Redshift Serverless instead of cluster"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "streaming_db"
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
  default     = 1
}

variable "namespace_name" {
  description = "Name of the Redshift Serverless namespace"
  type        = string
  default     = "streaming-namespace"
}

variable "workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  type        = string
  default     = "streaming-workgroup"
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
