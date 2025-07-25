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
  master_password      = var.master_password 
  manage_user_password = var.manage_user_password
  create_random_password   = var.create_random_password
  

  # Node configuration
  node_type       = var.node_type
  number_of_nodes = var.number_of_nodes
  cluster_type    = var.cluster_type

  # Network configuration
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  cluster_subnet_group_name = var.cluster_subnet_group_name
  cluster_parameter_group_name = var.cluster_parameter_group_name
  security_group_data    = var.security_group_data
  security_group_name    = var.security_group_name
  create_security_groups   = var.create_security_groups
 

  # Snapshot configuration
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.final_snapshot_identifier
  snapshot_identifier                 = var.snapshot_identifier
  automated_snapshot_retention_period = var.automated_snapshot_retention_period

  # Other configuration
  port                         = var.port
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
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  manage_admin_password = var.manage_admin_password

  create_random_password   = var.create_random_password
  create_security_groups   = var.create_security_groups

  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  port                = var.port
  enhanced_vpc_routing = var.enhanced_vpc_routing
  track_name          = var.track_name
  publicly_accessible = var.publicly_accessible

  config_parameters   = var.config_parameters

  kms_key_id          = var.kms_key_id

  security_group_name           = var.security_group_name
  additional_security_group_ids = var.additional_security_group_ids
  security_group_data           = var.security_group_data

  # Tags - pass through the tags from the calling module
  tags = var.tags
}
