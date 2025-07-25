variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "namespace" {
  description = "Namespace for the project"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "security_group_name" {
  type        = string
  description = "Redshift Serverless resourcesr security group name"
  default     = "Redshift-Serverless-sg"
}

# RDS variables
variable "rds_database_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "sourcedb"
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "rds_master_password" {
  description = "Master password for RDS"
  type        = string
  default     = null  # Will be auto-generated if null
}

# Redshift variables
variable "redshift_database_name" {
  description = "Name of the Redshift database"
  type        = string
  default     = "targetdb"
}

variable "redshift_master_username" {
  description = "Master username for Redshift"
  type        = string
  default     = "admin"
}

variable "redshift_master_password" {
  description = "Master password for Redshift"
  type        = string
  default     = null  # Will be auto-generated if null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Project     = "RDS-to-Redshift-Zero-ETL"
    ManagedBy   = "Terraform"
  }
}
