###############################################################################
####################     redshift cluster   ##################################
###############################################################################

locals {
  cluster_identifier = var.cluster_identifier != null ? var.cluster_identifier : "${var.namespace}-${var.environment}-${var.name}"
}

resource "aws_redshift_subnet_group" "this" {
  count = length(var.subnet_ids) > 0 && var.cluster_subnet_group_name == null ? 1 : 0

  name        = "${local.cluster_identifier}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Redshift subnet group for ${local.cluster_identifier}"

  tags = var.tags
}

###################################################################
#                Security Group
###################################################################
module "arc_security_group" {
  source  = "sourcefuse/arc-security-group/aws"
  version = "0.0.1"

  count         = var.create_security_groups ? 1 : 0
  name          = var.security_group_name
  vpc_id        = var.vpc_id
  ingress_rules = var.security_group_data.ingress_rules
  egress_rules  = var.security_group_data.egress_rules

  tags = var.tags
}

resource "random_password" "master_password" {
  count = var.create_random_password ? 1 : 0

  length           = 16
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# SSM Parameter Store for Redshift Password (only if password is provided)
resource "aws_ssm_parameter" "redshift_master_password" {
  count = var.create_random_password ? 1 : 0

  name        = "/${var.namespace}/${var.environment}/${var.name}/redshift/master-password"
  description = "Master password for Redshift cluster"
  type        = "SecureString"
  value       = var.create_random_password ? random_password.master_password[0].result : var.master_password

  tags = var.tags

}
resource "aws_redshift_logging" "example" {
  count                = var.redshift_logging.enable ? 1 : 0
  cluster_identifier   = local.cluster_identifier
  log_destination_type = var.redshift_logging.log_destination_type
  bucket_name          = var.redshift_logging.bucket_name
  s3_key_prefix        = var.redshift_logging.s3_key_prefix
}


resource "aws_redshift_cluster" "this" {
  cluster_identifier     = local.cluster_identifier
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = coalesce(var.manage_user_password, false) ? null : (var.create_random_password ? random_password.master_password[0].result : var.master_password)
  manage_master_password = var.manage_user_password
  node_type              = var.node_type

  # Cluster sizing
  number_of_nodes = var.cluster_type == "single-node" ? 1 : var.number_of_nodes
  cluster_type    = var.cluster_type

  # Network configuration
  cluster_subnet_group_name = var.cluster_subnet_group_name != null ? var.cluster_subnet_group_name : (
    length(aws_redshift_subnet_group.this) > 0 ? aws_redshift_subnet_group.this[0].name : null
  )

  vpc_security_group_ids = concat(var.create_security_groups ? [for sg in module.arc_security_group : sg.id] : [], var.additional_security_group_ids)
  # Snapshot configuration
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${local.cluster_identifier}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  )
  snapshot_identifier = var.snapshot_identifier

  # Maintenance and backup
  automated_snapshot_retention_period = var.automated_snapshot_retention_period
  port                                = var.port
  cluster_parameter_group_name        = var.cluster_parameter_group_name

  # Access and routing
  publicly_accessible  = var.publicly_accessible
  enhanced_vpc_routing = var.enhanced_vpc_routing

  # Encryption
  kms_key_id = var.kms_key_id
  encrypted  = var.encrypted

  # Upgrades
  allow_version_upgrade = var.allow_version_upgrade

  tags = var.tags

  lifecycle {
    ignore_changes = [
      automated_snapshot_retention_period,
      availability_zone_relocation_enabled,
      cluster_type,
      preferred_maintenance_window,
      allow_version_upgrade,
      number_of_nodes,
      final_snapshot_identifier,
    ]
  }
}
