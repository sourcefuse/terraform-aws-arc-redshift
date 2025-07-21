################################################################################
## Variables for URL Event Streaming Example
################################################################################

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
  description = "Name of the URL event streaming platform"
  type        = string
  default     = "url-event-streaming"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "url-event-streaming-platform"
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
  
  validation {
    condition     = contains(["PROVISIONED", "ON_DEMAND"], var.kinesis_stream_mode)
    error_message = "Stream mode must be either PROVISIONED or ON_DEMAND."
  }
}

# ALB Configuration
variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

# Redshift Configuration
variable "enable_serverless" {
  description = "Enable Redshift Serverless instead of cluster"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "url_events_db"
}

variable "master_username" {
  description = "Master username for Redshift"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Master password for Redshift (leave null for auto-generation)"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_user_password" {
  description = "Use AWS Secrets Manager for password management"
  type        = bool
  default     = false
}

# Cluster Configuration (when serverless is disabled)
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

# Serverless Configuration (when serverless is enabled)
variable "namespace_name" {
  description = "Name of the Redshift Serverless namespace"
  type        = string
  default     = "url-events-namespace"
}

variable "workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  type        = string
  default     = "url-events-workgroup"
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

# Event Collection Configuration
variable "enable_real_time_analytics" {
  description = "Enable real-time analytics with Kinesis Analytics"
  type        = bool
  default     = true
}

variable "enable_event_enrichment" {
  description = "Enable event enrichment in Firehose processing"
  type        = bool
  default     = true
}

variable "firehose_buffer_size" {
  description = "Buffer size for Firehose delivery (MB)"
  type        = number
  default     = 5
}

variable "firehose_buffer_interval" {
  description = "Buffer interval for Firehose delivery (seconds)"
  type        = number
  default     = 300
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

# Performance Configuration
variable "lambda_timeout_seconds" {
  description = "Timeout for Lambda functions (seconds)"
  type        = number
  default     = 30
}

variable "lambda_memory_mb" {
  description = "Memory allocation for Lambda functions (MB)"
  type        = number
  default     = 256
}

# Data Retention Configuration
variable "s3_backup_retention_days" {
  description = "Number of days to retain S3 backup data"
  type        = number
  default     = 90
}

variable "enable_s3_lifecycle_policies" {
  description = "Enable S3 lifecycle policies for cost optimization"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for all services"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit for all services"
  type        = bool
  default     = true
}

# Cost Optimization
variable "enable_kinesis_scaling" {
  description = "Enable auto-scaling for Kinesis streams"
  type        = bool
  default     = false
}

variable "kinesis_scaling_target_utilization" {
  description = "Target utilization percentage for Kinesis auto-scaling"
  type        = number
  default     = 70
}
