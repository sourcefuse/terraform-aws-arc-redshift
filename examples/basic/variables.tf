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
  default     = false
}

variable "node_type" {
  description = "Node type for the Redshift cluster"
  type        = string
  default     = "dc2.large"
}

variable "node_count" {
  description = "Number of nodes in the Redshift cluster"
  type        = number
  default     = 2
}
