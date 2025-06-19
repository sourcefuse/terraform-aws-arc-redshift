################################################################################
## defaults
################################################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "tags" {
  source  = "sourcefuse/arc-tags/aws"
  version = "1.2.6"

  environment = terraform.workspace
  project     = "terraform-aws-arc-redshift"

  extra_tags = {
    Example = "True"
  }
}

################################################################################
## Basic Redshift Cluster
################################################################################
module "redshift" {
  source = "../.."

  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  # Network configuration - using the subnets we created
  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.private.ids

  # Cluster configuration
  database_name        = var.database_name
  master_username      = var.master_username
  master_password      = var.master_password # Will use random password if null
  manage_user_password = var.manage_user_password
  node_type            = var.node_type
  number_of_nodes      = var.node_count
  cluster_type         = var.node_count > 1 ? "multi-node" : "single-node"

  # Security configuration
  ingress_rules = [
    {
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # Other configuration
  skip_final_snapshot = true
  publicly_accessible = false
  encrypted           = true

  tags = module.tags.tags
}
