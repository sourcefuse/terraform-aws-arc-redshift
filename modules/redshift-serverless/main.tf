locals {
  namespace_name         = var.namespace_name != null ? var.namespace_name : "${var.namespace}-${var.environment}-${var.name}-ns"
  workgroup_name         = var.workgroup_name != null ? var.workgroup_name : "${var.namespace}-${var.environment}-${var.name}-wg"
  security_group_name    = var.security_group_name != "" ? var.security_group_name : "${var.namespace}-${var.environment}-${var.name}-sg"
  redshift_admin_password = var.manage_admin_password ? null : (
    var.create_random_password ? random_password.master_password[0].result : var.master_password
  )
}
# Namespace - Managed by AWS (uses manage_admin_password)
resource "aws_redshiftserverless_namespace" "managed" {
  count = var.manage_admin_password ? 1 : 0

  namespace_name         = local.namespace_name
  db_name                = var.db_name
  kms_key_id             = var.kms_key_id
  manage_admin_password  = true

  tags = var.tags
}

# Namespace - Custom credentials
resource "aws_redshiftserverless_namespace" "custom" {
  count = var.manage_admin_password ? 0 : 1

  namespace_name        = local.namespace_name
  db_name               = var.db_name
  kms_key_id            = var.kms_key_id
  admin_username        = var.admin_username
  admin_user_password   = local.redshift_admin_password

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

# Generate random password if needed
resource "random_password" "master_password" {
  count = var.create_random_password && !var.manage_admin_password ? 1 : 0

  length           = 16
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in SSM only if not managed and generated
resource "aws_ssm_parameter" "redshift_master_password" {
  count = var.create_random_password && !var.manage_admin_password ? 1 : 0

  name        = "/${var.namespace}/${var.environment}/${var.name}/redshift/master-password"
  description = "Master password for Redshift Serverless namespace"
  type        = "SecureString"
  value       = random_password.master_password[count.index].result

  tags = var.tags
}
resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name = local.workgroup_name
  namespace_name = var.manage_admin_password ? aws_redshiftserverless_namespace.managed[0].namespace_name : aws_redshiftserverless_namespace.custom[0].namespace_name
  
  base_capacity = var.base_capacity
  max_capacity  = var.max_capacity
  port                  = var.port
  enhanced_vpc_routing  = var.enhanced_vpc_routing
  track_name            = var.track_name
  
  publicly_accessible = var.publicly_accessible

   # Optional Config Parameters (loopable)
  dynamic "config_parameter" {
    for_each = var.config_parameters != null ? var.config_parameters : []
    content {
      parameter_key   = config_parameter.value.parameter_key
      parameter_value = config_parameter.value.parameter_value
    }
  }
  
  # Network configuration
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : null
  
  security_group_ids = concat(var.create_security_groups ? [for sg in module.arc_security_group : sg.id] : [], var.additional_security_group_ids)
   tags = var.tags
  
  depends_on = [
    aws_redshiftserverless_namespace.managed,
    aws_redshiftserverless_namespace.custom
  ]
}