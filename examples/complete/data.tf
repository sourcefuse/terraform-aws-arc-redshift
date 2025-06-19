################################################
## imports
################################################
## vpc
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.namespace}-${var.environment}-vpc"]
  }
}

## network
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name = "tag:Name"
    values = [
      "*private*"
    ]
  }
}

# Add AWS caller identity data source
data "aws_caller_identity" "current" {}

locals {
  subnet_ids = data.aws_subnets.private.ids
}
