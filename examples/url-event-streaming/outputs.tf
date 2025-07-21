################################################################################
## Outputs for URL Event Streaming Example
################################################################################

# Event Collection Endpoints
output "event_collection_url" {
  description = "URL for collecting events via HTTPS"
  value       = "https://${aws_lb.event_collector.dns_name}"
}

output "event_collection_endpoints" {
  description = "Available endpoints for event collection"
  value = {
    post_events    = "https://${aws_lb.event_collector.dns_name}/collect"
    get_events     = "https://${aws_lb.event_collector.dns_name}/track"
    pixel_tracking = "https://${aws_lb.event_collector.dns_name}/pixel.gif"
    js_tracker     = "https://${aws_lb.event_collector.dns_name}/js/tracker.js"
    health_check   = "https://${aws_lb.event_collector.dns_name}/health"
  }
}

# Load Balancer Information
output "load_balancer_dns_name" {
  description = "DNS name of the event collection load balancer"
  value       = aws_lb.event_collector.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the event collection load balancer"
  value       = aws_lb.event_collector.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the event collection load balancer"
  value       = aws_lb.event_collector.arn
}

# Kinesis Streams
output "kinesis_url_events_stream_name" {
  description = "Name of the URL events Kinesis stream"
  value       = aws_kinesis_stream.url_events.name
}

output "kinesis_url_events_stream_arn" {
  description = "ARN of the URL events Kinesis stream"
  value       = aws_kinesis_stream.url_events.arn
}

output "kinesis_processed_events_stream_name" {
  description = "Name of the processed events Kinesis stream"
  value       = aws_kinesis_stream.processed_events.name
}

output "kinesis_processed_events_stream_arn" {
  description = "ARN of the processed events Kinesis stream"
  value       = aws_kinesis_stream.processed_events.arn
}

# Kinesis Analytics
output "kinesis_analytics_application_name" {
  description = "Name of the Kinesis Analytics application"
  value       = aws_kinesis_analytics_application.event_processor.name
}

output "kinesis_analytics_application_arn" {
  description = "ARN of the Kinesis Analytics application"
  value       = aws_kinesis_analytics_application.event_processor.arn
}

# Kinesis Firehose
output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.redshift_delivery.name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.redshift_delivery.arn
}

# Lambda Functions
output "event_collector_lambda_arn" {
  description = "ARN of the event collector Lambda function"
  value       = aws_lambda_function.event_collector.arn
}

output "event_collector_lambda_name" {
  description = "Name of the event collector Lambda function"
  value       = aws_lambda_function.event_collector.function_name
}

output "event_enricher_lambda_arn" {
  description = "ARN of the event enricher Lambda function"
  value       = aws_lambda_function.event_enricher.arn
}

output "event_enricher_lambda_name" {
  description = "Name of the event enricher Lambda function"
  value       = aws_lambda_function.event_enricher.function_name
}

# S3 Buckets
output "event_backup_bucket_name" {
  description = "Name of the event backup S3 bucket"
  value       = aws_s3_bucket.event_backup.bucket
}

output "event_backup_bucket_arn" {
  description = "ARN of the event backup S3 bucket"
  value       = aws_s3_bucket.event_backup.arn
}

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

# Redshift Information
output "redshift_endpoint" {
  description = "Redshift endpoint for connecting to the data warehouse"
  value = var.enable_serverless ? (
    length(module.redshift.serverless_workgroup_endpoint) > 0 ? 
    module.redshift.serverless_workgroup_endpoint[0].address : ""
  ) : module.redshift.cluster_endpoint
}

output "redshift_database_name" {
  description = "Name of the Redshift database"
  value       = var.database_name
}

output "redshift_master_username" {
  description = "Master username for Redshift"
  value       = var.master_username
  sensitive   = true
}

output "redshift_cluster_identifier" {
  description = "Redshift cluster identifier (if using cluster mode)"
  value       = var.enable_serverless ? null : module.redshift.cluster_identifier
}

output "redshift_workgroup_name" {
  description = "Redshift Serverless workgroup name (if using serverless mode)"
  value       = var.enable_serverless ? module.redshift.serverless_workgroup_name : null
}

# Security
output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.streaming.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.streaming.arn
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# Monitoring
output "cloudwatch_alarms" {
  description = "CloudWatch alarm names for monitoring"
  value = {
    kinesis_incoming_records = aws_cloudwatch_metric_alarm.kinesis_stream_incoming_records.alarm_name
    lambda_errors           = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
    firehose_delivery_errors = aws_cloudwatch_metric_alarm.firehose_delivery_errors.alarm_name
  }
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    event_collector    = aws_cloudwatch_log_group.event_collector_logs.name
    event_enricher     = aws_cloudwatch_log_group.event_enricher_logs.name
    kinesis_analytics  = aws_cloudwatch_log_group.kinesis_analytics_logs.name
  }
}

# Integration Information
output "integration_guide" {
  description = "Guide for integrating with the URL event streaming platform"
  value = {
    javascript_integration = {
      script_url = "https://${aws_lb.event_collector.dns_name}/js/tracker.js"
      usage = "Add <script src='https://${aws_lb.event_collector.dns_name}/js/tracker.js'></script> to your website"
      custom_events = "Use window.urlTracker.track('event_name', {custom: 'data'}) for custom events"
    }
    
    server_side_integration = {
      post_endpoint = "https://${aws_lb.event_collector.dns_name}/collect"
      get_endpoint = "https://${aws_lb.event_collector.dns_name}/track"
      pixel_endpoint = "https://${aws_lb.event_collector.dns_name}/pixel.gif"
      content_type = "application/json"
      method = "POST"
    }
    
    data_format = {
      required_fields = ["event_type", "url", "timestamp"]
      optional_fields = ["user_id", "session_id", "user_agent", "referrer", "custom_data"]
      example = {
        event_type = "page_view"
        url = "https://example.com/page"
        timestamp = "2024-01-01T12:00:00Z"
        user_id = "user_123"
        session_id = "session_456"
        custom_data = {
          product_id = "prod_789"
          category = "electronics"
        }
      }
    }
  }
}

# Performance Metrics
output "expected_throughput" {
  description = "Expected throughput capabilities"
  value = {
    kinesis_records_per_second = var.kinesis_shard_count * 1000
    lambda_concurrent_executions = 1000
    firehose_records_per_second = 5000
    estimated_cost_per_million_events = "~$2-5 USD (varies by region and usage patterns)"
  }
}

# Data Flow Information
output "data_flow_summary" {
  description = "Summary of the data flow through the system"
  value = {
    step_1 = "Web events collected via ALB → Lambda (Event Collector)"
    step_2 = "Events streamed to Kinesis Data Streams (Raw Events)"
    step_3 = "Real-time processing via Kinesis Analytics (Aggregations & Analytics)"
    step_4 = "Processed events sent to second Kinesis stream"
    step_5 = "Kinesis Firehose enriches events via Lambda (Event Enricher)"
    step_6 = "Final delivery to Redshift for long-term analytics"
    step_7 = "Backup data stored in S3 for disaster recovery"
  }
}

# Redshift Table Information
output "redshift_tables_to_create" {
  description = "SQL commands to create tables in Redshift for the event data"
  value = {
    url_events_table = <<-SQL
      CREATE TABLE IF NOT EXISTS url_events (
        event_id VARCHAR(64) PRIMARY KEY,
        timestamp TIMESTAMP NOT NULL,
        url VARCHAR(2048),
        user_id VARCHAR(128),
        session_id VARCHAR(128),
        user_agent VARCHAR(1024),
        ip_address VARCHAR(45),
        referrer VARCHAR(2048),
        page_title VARCHAR(500),
        event_type VARCHAR(50),
        domain VARCHAR(500),
        path VARCHAR(1000),
        query_string VARCHAR(1000),
        country VARCHAR(100),
        region VARCHAR(100),
        city VARCHAR(100),
        device_type VARCHAR(50),
        browser VARCHAR(50),
        os VARCHAR(50),
        utm_source VARCHAR(200),
        utm_medium VARCHAR(200),
        utm_campaign VARCHAR(200),
        processing_time TIMESTAMP,
        enrichment_timestamp TIMESTAMP,
        ingestion_time TIMESTAMP DEFAULT GETDATE()
      )
      DISTKEY(user_id)
      SORTKEY(timestamp);
    SQL
    
    session_analytics_table = <<-SQL
      CREATE TABLE IF NOT EXISTS session_analytics (
        session_id VARCHAR(128) PRIMARY KEY,
        user_id VARCHAR(128),
        session_start TIMESTAMP,
        session_end TIMESTAMP,
        page_views INTEGER,
        unique_pages INTEGER,
        session_duration_seconds INTEGER,
        bounce_flag INTEGER,
        conversion_flag INTEGER,
        window_timestamp TIMESTAMP,
        ingestion_time TIMESTAMP DEFAULT GETDATE()
      )
      DISTKEY(user_id)
      SORTKEY(session_start);
    SQL
  }
}
