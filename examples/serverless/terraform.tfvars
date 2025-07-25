region      = "us-east-1"
namespace   = "arc"
environment = "poc"
name        = "analytics"
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
# Toggle between standard Redshift and Redshift Serverless
# Use terraform apply -var-file=dev.tfvars -var="enable_serverless=true" to deploy serverless
enable_serverless = true

# Common Configuration
database_name   = "analytics"
master_username = "admin"


# Serverless Redshift settings (used when enable_serverless = true)
namespace_name = "analytics-namespace"
workgroup_name = "analytics-workgroup"
base_capacity  = 32
max_capacity   = 128

# Feature Flags - Core Features
enable_encryption  = false
enable_logging     = true
enable_monitoring  = true
enable_maintenance = true

# Feature Flags - Integrations
enable_s3_integration       = true
enable_s3_event_integration = false
enable_zero_etl             = false

# S3 Event Integration Configuration
s3_filter_prefix      = "data/"
s3_filter_suffix      = ".csv"
redshift_target_table = "public.events"

# Network settings
publicly_accessible = false

# Other settings
skip_final_snapshot                 = true
automated_snapshot_retention_period = 7
