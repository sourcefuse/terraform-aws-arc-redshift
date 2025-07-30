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

variable "security_group_data" {
  type = object({
    security_group_ids_to_attach = optional(list(string), [])
    create                       = optional(bool, true)
    description                  = optional(string, null)
    ingress_rules = optional(list(object({
      description              = optional(string, null)
      cidr_block               = optional(string, null)
      source_security_group_id = optional(string, null)
      from_port                = number
      ip_protocol              = string
      to_port                  = string
      self                     = optional(bool, false)
    })), [])
    egress_rules = optional(list(object({
      description                   = optional(string, null)
      cidr_block                    = optional(string, null)
      destination_security_group_id = optional(string, null)
      from_port                     = number
      ip_protocol                   = string
      to_port                       = string
      prefix_list_id                = optional(string, null)
    })), [])
  })
  description = "(optional) Security Group data"
  default = {
    create = false
  }
}
variable "security_group_name" {
  type        = string
  description = "Redshift Serverless resourcesr security group name"
  default     = "Redshift-Serverless-sg"
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
