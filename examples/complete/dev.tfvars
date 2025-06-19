region      = "us-east-1"
namespace   = "arc"
environment = "poc"
name        = "analytics"

# Toggle between standard Redshift and Redshift Serverless
# Use terraform apply -var-file=dev.tfvars -var="enable_serverless=true" to deploy serverless
enable_serverless = false

# Common Configuration
database_name   = "analytics"
master_username = "admin"
# master_password   = "StrongPassword123!" # Uncomment to use manual password
master_password = null # Use random password generation (recommended)

# Standard Redshift settings (used when enable_serverless = false)
node_type  = "ra3.large" # Updated to a valid node type
node_count = 1

# Serverless Redshift settings (used when enable_serverless = true)
namespace_name = "analytics-namespace"
workgroup_name = "analytics-workgroup"
base_capacity  = 32
max_capacity   = 128

# Feature Flags - Core Features
enable_encryption  = true
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
