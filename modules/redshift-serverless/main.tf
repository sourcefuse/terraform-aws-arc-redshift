###############################################################################
####################     redshift serverless   #############################
###############################################################################

locals {
  namespace_name = var.namespace_name != null ? var.namespace_name : "${var.namespace}-${var.environment}-${var.name}-ns"
  workgroup_name = var.workgroup_name != null ? var.workgroup_name : "${var.namespace}-${var.environment}-${var.name}-wg"
  security_group_name = var.security_group_name != "" ? var.security_group_name : "${var.namespace}-${var.environment}-${var.name}-sg"
}

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = local.namespace_name
  admin_username = var.admin_username
  admin_user_password = var.admin_password
  manage_admin_password = var.manage_user_password
  db_name = var.db_name
  
  kms_key_id = var.kms_key_id
  
  tags = merge(
    var.tags,
    {
      Name        = local.namespace_name
      Environment = var.environment
      Namespace   = var.namespace
    }
  )
}

resource "aws_security_group" "this" {
  count = var.vpc_id != null ? 1 : 0
  
  name        = local.security_group_name
  description = "Security group for Redshift Serverless workgroup ${local.workgroup_name}"
  vpc_id      = var.vpc_id
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = "Redshift Serverless ingress rule"
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = "Redshift Serverless egress rule"
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

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name = local.workgroup_name
  namespace_name = aws_redshiftserverless_namespace.this.namespace_name
  
  base_capacity = var.base_capacity
  max_capacity  = var.max_capacity
  
  publicly_accessible = var.publicly_accessible
  
  # Network configuration
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : null
  
  security_group_ids = concat(
    var.vpc_security_group_ids,
    length(aws_security_group.this) > 0 ? [aws_security_group.this[0].id] : []
  )
  
  tags = merge(
    var.tags,
    {
      Name        = local.workgroup_name
      Environment = var.environment
      Namespace   = var.namespace
    }
  )
  
  depends_on = [aws_redshiftserverless_namespace.this]
}
