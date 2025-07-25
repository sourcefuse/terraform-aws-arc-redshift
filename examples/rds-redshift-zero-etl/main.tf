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


# RDS PostgreSQL Database using SourceFuse ARC module
locals {
  redshift_security_group_data = {
    create      = true
    description = "Security Group for redshift instance"

    ingress_rules = [
      {
        description = "Allow traffic from local network"
        cidr_block  = data.aws_vpc.this.cidr_block
        from_port   = 5432
        ip_protocol = "tcp"
        to_port     = 5432
      }
    ]

    egress_rules = [
      {
        description = "Allow all outbound traffic"
        cidr_block  = "0.0.0.0/0"
        from_port   = -1
        ip_protocol = "-1"
        to_port     = -1
      }
    ]
  }
}


module "rds" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.1"

  environment                     = var.environment
  namespace                       = var.namespace
  vpc_id                          = data.aws_vpc.this.id
  name                            = "${var.namespace}-${var.environment}-test"
  engine_type                     = "cluster"
  port                            = 5432
  username                        = "postgres"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.05.2"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.mysql_zerotetl.name

  license_model = "general-public-license"
  rds_cluster_instances = [
    {
      instance_class    = "db.r5.large"
      apply_immediately = true
      promotion_tier    = 1
    }
  ]

  db_subnet_group_data = {
    name        = "${var.namespace}-${var.environment}-subnet-group"
    create      = true
    description = "Subnet group for rds instance"
    subnet_ids  = data.aws_subnets.private.ids
  }

  performance_insights_enabled = true

  kms_data = {
    create                  = true
    description             = "KMS for Performance insight and storage"
    deletion_window_in_days = 7
    enable_key_rotation     = true
  }
  depends_on = [aws_rds_cluster_parameter_group.mysql_zerotetl]
}

# Redshift Cluster using your module
module "redshift" {
  source = "../../"

  namespace   = var.namespace
  environment = var.environment
  name        = "${var.namespace}-${var.environment}-redshift"

  enable_serverless = false

  # Cluster configuration
  database_name          = var.redshift_database_name
  master_username        = var.redshift_master_username
  create_random_password = true
  node_type              = "ra3.large" # Must be RA3 for Zero-ETL
  cluster_type           = "multi-node"
  number_of_nodes        = 2

  # Network configuration
  vpc_id              = data.aws_vpc.this.id
  subnet_ids          = data.aws_subnets.private.ids
  security_group_data = local.redshift_security_group_data
  security_group_name = var.security_group_name
  publicly_accessible = false

  # Security
  encrypted = true

  tags = var.tags
}


# Create Zero-ETL integration
resource "aws_rds_integration" "this" {
  integration_name = "zero-etl-integration-1"
  source_arn       = module.rds.arn
  target_arn       = module.redshift.redshift_cluster_namespace_arn

  # data_filter = ""

  lifecycle {
    ignore_changes = [
      kms_key_id
    ]
  }
  depends_on = [aws_redshift_resource_policy.account, module.rds]
}

resource "aws_rds_cluster_parameter_group" "mysql_zerotetl" {
  name        = "aurora-mysql-zeroetl"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 - Zero ETL support with Redshift"

  dynamic "parameter" {
    for_each = local.aurora_mysql_zerotetl_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

}


locals {

  aurora_mysql_zerotetl_parameters = {
    aurora_enhanced_binlog = {
      value        = "1"
      apply_method = "pending-reboot"
    }
    binlog_backup = {
      value        = "0"
      apply_method = "pending-reboot"
    }
    binlog_format = {
      value        = "ROW"
      apply_method = "pending-reboot"
    }
    binlog_replication_globaldb = {
      value        = "0"
      apply_method = "pending-reboot"
    }
    binlog_row_image = {
      value        = "full"
      apply_method = "pending-reboot"
    }
    binlog_row_metadata = {
      value        = "full"
      apply_method = "pending-reboot"
    }
    binlog_transaction_compression = {
      value        = "OFF"
      apply_method = "pending-reboot"
    }
    binlog_row_value_options = {
      value        = ""
      apply_method = "pending-reboot"
    }
    log_bin_trust_function_creators = {
      value        = "1"
      apply_method = "pending-reboot"
    }
  }
}
resource "aws_redshift_resource_policy" "account" {
  resource_arn = module.redshift.redshift_cluster_namespace_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action   = "redshift:CreateInboundIntegration"
      Resource = module.redshift.redshift_cluster_namespace_arn
      Sid      = ""
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        },
        Action = "redshift:AuthorizeInboundIntegration",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = module.rds.arn
          }
        }
    }]
  })
}
