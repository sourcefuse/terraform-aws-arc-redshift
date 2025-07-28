#################################################
############     common variables    ############
#################################################

variable "environment" {
  type        = string
  description = "Name of the environment, i.e. dev, stage, prod"
}

variable "namespace" {
  type        = string
  description = "Namespace of the project, i.e. arc"
}

variable "enable_serverless" {
  description = "Enable Redshift Serverless. If true, creates the serverless module; if false, creates the standard cluster module."
  type        = bool
  default     = false
}

#####################################################################
####################     redshift cluster   ########################
#####################################################################

variable "name" {
  description = "Name for the Redshift resources"
  type        = string
}

variable "cluster_identifier" {
  description = "The Cluster Identifier"
  type        = string
  default     = null
}

variable "database_name" {
  description = "The name of the database to create"
  type        = string
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "manage_admin_password" {
  description = "If true, Redshift will manage the admin password"
  type        = bool
  default     = false
}
variable "create_security_groups" {
  description = "Whether to create security groups for Redshift Serverless resources"
  type        = bool
  default     = true
}
variable "redshift_logging" {
  description = "Configuration for Redshift logging"
  type = object({
    enable               = optional(bool, false)
    bucket_name          = optional(string, null)
    s3_key_prefix        = optional(string, "redshift-logs/")
    log_destination_type = optional(string, "s3")
  })
  default = {
    enable = false
  }
}

variable "create_random_password" {
  description = "Determines whether to create random password for cluster `master_password`"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Admin username for the Redshift Serverless namespace."
  type        = string
  default     = "admin"
}

variable "track_name" {
  description = "Optional track name for Redshift Serverless (used for versioning or preview tracks)."
  type        = string
  default     = null
}

variable "config_parameters" {
  description = "A list of configuration parameters to apply to the Redshift Serverless namespace."
  type = list(object({
    parameter_key   = string
    parameter_value = string
  }))
  default = []
}
variable "additional_security_group_ids" {
  description = "Additional security group IDs to be added to the Redshift Serverless workgroup."
  type        = list(string)
  default     = []
}
# variable "master_password" {
#   description = "Password for the master DB user. If null, a random password will be generated"
#   type        = string
#   sensitive   = true
#   default     = null
# }

variable "manage_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = null
}

variable "node_type" {
  description = "The node type to be provisioned for the cluster"
  type        = string
  default     = "dc2.large"
}

variable "number_of_nodes" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "cluster_type" {
  description = "The cluster type to use. Either 'single-node' or 'multi-node'"
  type        = string
  default     = "single-node"
}

variable "cluster_subnet_group_name" {
  description = "The name of a cluster subnet group to be associated with this cluster. If not specified, a new subnet group will be created"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final snapshot of the cluster is created before Redshift deletes it"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The identifier of the final snapshot that is to be created immediately before deleting the cluster"
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "The name of the snapshot from which to create the new cluster"
  type        = string
  default     = null
}

variable "automated_snapshot_retention_period" {
  description = "The number of days that automated snapshots are retained"
  type        = number
  default     = 7
}

variable "port" {
  description = "The port number on which the cluster accepts incoming connections"
  type        = number
  default     = 5439
}

variable "cluster_parameter_group_name" {
  description = "The name of the parameter group to be associated with this cluster"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "If true, the cluster can be accessed from a public network"
  type        = bool
  default     = false
}

variable "enhanced_vpc_routing" {
  description = "If true, enhanced VPC routing is enabled"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "encrypted" {
  description = "If true, the data in the cluster is encrypted at rest"
  type        = bool
  default     = true
}

variable "allow_version_upgrade" {
  description = "If true, major version upgrades can be applied during maintenance windows"
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Redshift subnet group"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "ID of the VPC for Redshift"
  type        = string
  default     = null
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

##################################################
######## Redshift Serverless Variables  ##########
##################################################

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

variable "base_capacity" {
  description = "The base data warehouse capacity in Redshift Processing Units (RPUs)"
  type        = number
  default     = 32
}

variable "max_capacity" {
  description = "The maximum data warehouse capacity in Redshift Processing Units (RPUs)"
  type        = number
  default     = 512
}
