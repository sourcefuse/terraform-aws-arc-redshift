################################################################################
## VPC and Networking Resources
################################################################################
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["arc-poc-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "tag:Name"
    values = [
      "${var.namespace}-${var.environment}-private-subnet-private-${var.region}a",
      "${var.namespace}-${var.environment}-private-subnet-private-${var.region}b"
    ]
  }
}
