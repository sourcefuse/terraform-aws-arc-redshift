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

variable "manage_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = null
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
