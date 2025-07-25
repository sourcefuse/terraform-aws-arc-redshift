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


variable "security_group_name" {
  type        = string
  description = "Redshift Serverless resourcesr security group name"
  default     = "Redshift-Serverless-sg"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project   = "RDS-to-Redshift-Zero-ETL"
    ManagedBy = "Terraform"
  }
}
