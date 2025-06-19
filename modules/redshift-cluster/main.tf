###############################################################################
####################     redshift cluster   ##################################
###############################################################################

locals {
  cluster_identifier = var.cluster_identifier != null ? var.cluster_identifier : "${var.namespace}-${var.environment}-${var.name}"
  security_group_name = var.security_group_name != "" ? var.security_group_name : "${var.namespace}-${var.environment}-${var.name}-sg"
}

resource "aws_redshift_subnet_group" "this" {
  count = length(var.subnet_ids) > 0 && var.cluster_subnet_group_name == null ? 1 : 0
  
  name        = "${local.cluster_identifier}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Redshift subnet group for ${local.cluster_identifier}"
  
  tags = merge(
    var.tags,
    {
      Name        = "${local.cluster_identifier}-subnet-group"
      Environment = var.environment
      Namespace   = var.namespace
    }
  )
}

resource "aws_security_group" "this" {
  count = var.vpc_id != null ? 1 : 0
  
  name        = local.security_group_name
  description = "Security group for Redshift cluster ${local.cluster_identifier}"
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = "Redshift ingress rule"
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = "Redshift egress rule"
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name        = local.security_group_name
      Environment = var.environment
      Namespace   = var.namespace
    }
  )
}

resource "aws_redshift_cluster" "this" {
  cluster_identifier = local.cluster_identifier
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password
  manage_master_password = var.manage_user_password
  node_type          = var.node_type
  
  # Cluster sizing
  number_of_nodes    = var.cluster_type == "single-node" ? 1 : var.number_of_nodes
  cluster_type       = var.cluster_type
  
  # Network configuration
  cluster_subnet_group_name = var.cluster_subnet_group_name != null ? var.cluster_subnet_group_name : (
    length(aws_redshift_subnet_group.this) > 0 ? aws_redshift_subnet_group.this[0].name : null
  )
  
  vpc_security_group_ids = concat(
    var.vpc_security_group_ids,
    length(aws_security_group.this) > 0 ? [aws_security_group.this[0].id] : []
  )
  
  # Snapshot configuration
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${local.cluster_identifier}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  )
  snapshot_identifier      = var.snapshot_identifier
  
  # Maintenance and backup
  automated_snapshot_retention_period = var.automated_snapshot_retention_period
  port                     = var.port
  cluster_parameter_group_name = var.cluster_parameter_group_name
  
  # Access and routing
  publicly_accessible      = var.publicly_accessible
  enhanced_vpc_routing     = var.enhanced_vpc_routing
  
  # Encryption
  kms_key_id               = var.kms_key_id
  encrypted                = var.encrypted
  
  # Upgrades
  allow_version_upgrade    = var.allow_version_upgrade
  
  tags = merge(
    var.tags,
    {
      Name        = local.cluster_identifier
      Environment = var.environment
      Namespace   = var.namespace
    }
  )
  
  lifecycle {
    prevent_destroy = false
  }
}
