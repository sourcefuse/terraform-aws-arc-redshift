###############################################################################
####################     redshift module   ##################################
###############################################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

data "aws_caller_identity" "current" {}

###############################################################################
####################     Random Password Generation   #######################
###############################################################################

resource "random_password" "master" {
  count = var.master_password == null && var.manage_user_password == null ? 1 : 0

  length           = 41
  special          = true
  override_special = "!#*^"

  lifecycle {
    ignore_changes = [
      length,
      special,
      override_special
    ]
  }
}

###############################################################################
####################     Standard Redshift Module Call   ###################
###############################################################################

module "redshift_cluster" {
  count = var.enable_serverless ? 0 : 1

  source = "./modules/redshift-cluster"

  # Basic configuration
  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  # Cluster configuration
  cluster_identifier   = var.cluster_identifier
  database_name        = var.database_name
  master_username      = var.master_username
  master_password      = var.master_password == null && var.manage_user_password == null ? random_password.master[0].result : var.master_password
  manage_user_password = var.manage_user_password

  # Node configuration
  node_type       = var.node_type
  number_of_nodes = var.number_of_nodes
  cluster_type    = var.cluster_type

  # Network configuration
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  cluster_subnet_group_name = var.cluster_subnet_group_name
  vpc_security_group_ids    = var.vpc_security_group_ids
  security_group_name       = var.security_group_name

  # Security group rules
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules

  # Snapshot configuration
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.final_snapshot_identifier
  snapshot_identifier                 = var.snapshot_identifier
  automated_snapshot_retention_period = var.automated_snapshot_retention_period

  # Other configuration
  port                         = var.port
  cluster_parameter_group_name = var.cluster_parameter_group_name
  publicly_accessible          = var.publicly_accessible
  enhanced_vpc_routing         = var.enhanced_vpc_routing
  kms_key_id                   = var.kms_key_id
  encrypted                    = var.encrypted
  allow_version_upgrade        = var.allow_version_upgrade

  # Tags - pass through the tags from the calling module
  tags = var.tags
}

###############################################################################
####################     Serverless Redshift Module Call   ##################
###############################################################################

module "redshift_serverless" {
  count = var.enable_serverless ? 1 : 0

  source = "./modules/redshift-serverless"

  # Basic configuration
  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  # Serverless configuration
  namespace_name = var.namespace_name
  workgroup_name = var.workgroup_name
  base_capacity  = var.base_capacity
  max_capacity   = var.max_capacity

  # Database configuration
  db_name              = var.database_name
  admin_username       = var.master_username
  admin_password       = var.master_password == null && var.manage_user_password == null ? random_password.master[0].result : var.master_password
  manage_user_password = var.manage_user_password

  # Network configuration
  vpc_id                 = var.vpc_id
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  security_group_name    = var.security_group_name

  # Security group rules
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules

  # Other configuration
  publicly_accessible = var.publicly_accessible
  kms_key_id          = var.kms_key_id

  # Tags - pass through the tags from the calling module
  tags = var.tags
}
