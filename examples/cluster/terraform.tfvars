region          = "us-east-1"
namespace       = "arc"
environment     = "poc"
name            = "analytics"
database_name   = "analytics"
master_username = "admin"
node_type       = "ra3.xlplus"
node_count      = 2
security_group_name = "arc-redshift-sg"
security_group_data = {
  create      = true
  description = "Security Group for Redshift"
  ingress_rules = [
    {
      description = "Allow VPC traffic"
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      ip_protocol = "tcp"
      to_port     = 443
    },
    {
      description = "Allow traffic from self"
      self        = true
      from_port   = 80
      ip_protocol = "tcp"
      to_port     = 80
    },
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