region              = "us-east-1"
namespace           = "arc"
environment         = "poc"
name                = "analytics"
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

enable_serverless = true

# Common Configuration
database_name   = "analytics"
master_username = "admin"


# Serverless Redshift settings (used when enable_serverless = true)
namespace_name = "analytics-namespace"
workgroup_name = "analytics-workgroup"
base_capacity  = 32
max_capacity   = 128

# Network settings
publicly_accessible = false

# Other settings
skip_final_snapshot                 = true
automated_snapshot_retention_period = 7
