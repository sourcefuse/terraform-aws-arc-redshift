################################################################################
## defaults
################################################################################
terraform {
  required_version = "~> 1.3, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

################################################################################
## Tags Module
################################################################################
module "tags" {
  source  = "sourcefuse/arc-tags/aws"
  version = "1.2.3"

  environment = var.environment
  project     = var.project_name
}

################################################################################
## Resources for testing
################################################################################

# KMS Key for Redshift Encryption
resource "aws_kms_key" "redshift" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for Redshift cluster encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-redshift-key"
    }
  )
}

resource "aws_kms_alias" "redshift" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${var.namespace}-${var.environment}-${var.name}-redshift"
  target_key_id = aws_kms_key.redshift[0].key_id
}




################################################################################
## Redshift Module
################################################################################
module "redshift_serverless" {
  source = "../../"

  # Toggle between standard Redshift and Redshift Serverless
  enable_serverless = var.enable_serverless

  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  # Network configuration - using existing VPC and subnets
  vpc_id              = data.aws_vpc.vpc.id
  subnet_ids          = data.aws_subnets.private.ids
  security_group_data = var.security_group_data
  security_group_name = var.security_group_name

  # Common configuration
  database_name        = var.database_name
  master_username      = var.master_username
  manage_user_password = var.manage_user_password
  namespace_name       = var.namespace_name
  workgroup_name       = var.workgroup_name
  base_capacity        = var.base_capacity
  max_capacity         = var.max_capacity

  # Security configuration
  encrypted  = var.enable_encryption
  kms_key_id = var.enable_encryption ? aws_kms_key.redshift[0].arn : null

  # Other configuration
  skip_final_snapshot                 = var.skip_final_snapshot
  publicly_accessible                 = var.publicly_accessible
  enhanced_vpc_routing                = false
  allow_version_upgrade               = true
  automated_snapshot_retention_period = var.automated_snapshot_retention_period

  tags = module.tags.tags
}
