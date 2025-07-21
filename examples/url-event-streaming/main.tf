################################################################################
## URL Event Streaming to Redshift
## Real-time event capture from web applications with streaming to Redshift
################################################################################

terraform {
  required_version = "~> 1.3, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
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
## Data Sources
################################################################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

################################################################################
## Kinesis Data Streams for Real-time Event Streaming
################################################################################

# Main event stream for URL events
resource "aws_kinesis_stream" "url_events" {
  name             = "${var.namespace}-${var.environment}-${var.name}-url-events"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  shard_level_metrics = [
    "IncomingRecords",
    "OutgoingRecords",
    "IncomingBytes",
    "OutgoingBytes"
  ]

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.streaming.arn

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-url-events"
      Purpose = "URL event streaming"
    }
  )
}

# Secondary stream for processed events
resource "aws_kinesis_stream" "processed_events" {
  name             = "${var.namespace}-${var.environment}-${var.name}-processed-events"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.streaming.arn

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-processed-events"
      Purpose = "Processed event streaming"
    }
  )
}

################################################################################
## Kinesis Analytics Application for Real-time Processing
################################################################################

resource "aws_kinesis_analytics_application" "event_processor" {
  name = "${var.namespace}-${var.environment}-${var.name}-event-processor"

  inputs {
    name_prefix = "SOURCE_SQL_STREAM"
    
    input_schema {
      record_columns {
        name     = "event_id"
        sql_type = "VARCHAR(64)"
        mapping  = "$.event_id"
      }
      
      record_columns {
        name     = "timestamp"
        sql_type = "TIMESTAMP"
        mapping  = "$.timestamp"
      }
      
      record_columns {
        name     = "url"
        sql_type = "VARCHAR(2048)"
        mapping  = "$.url"
      }
      
      record_columns {
        name     = "user_id"
        sql_type = "VARCHAR(128)"
        mapping  = "$.user_id"
      }
      
      record_columns {
        name     = "session_id"
        sql_type = "VARCHAR(128)"
        mapping  = "$.session_id"
      }
      
      record_columns {
        name     = "user_agent"
        sql_type = "VARCHAR(1024)"
        mapping  = "$.user_agent"
      }
      
      record_columns {
        name     = "ip_address"
        sql_type = "VARCHAR(45)"
        mapping  = "$.ip_address"
      }
      
      record_columns {
        name     = "referrer"
        sql_type = "VARCHAR(2048)"
        mapping  = "$.referrer"
      }

      record_format {
        record_format_type = "JSON"
        
        mapping_parameters {
          json_mapping_parameters {
            record_row_path = "$"
          }
        }
      }
    }

    kinesis_stream {
      resource_arn = aws_kinesis_stream.url_events.arn
      role_arn     = aws_iam_role.kinesis_analytics.arn
    }
  }

  outputs {
    name = "DESTINATION_SQL_STREAM"
    
    destination_schema {
      record_format_type = "JSON"
    }
    
    kinesis_stream {
      resource_arn = aws_kinesis_stream.processed_events.arn
      role_arn     = aws_iam_role.kinesis_analytics.arn
    }
  }

  code = file("${path.module}/kinesis_analytics_sql.sql")

  tags = module.tags.tags
}

################################################################################
## Kinesis Data Firehose for Redshift Delivery
################################################################################

resource "aws_kinesis_firehose_delivery_stream" "redshift_delivery" {
  name        = "${var.namespace}-${var.environment}-${var.name}-redshift-delivery"
  destination = "redshift"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.processed_events.arn
    role_arn          = aws_iam_role.firehose_delivery.arn
  }

  redshift_configuration {
    role_arn        = aws_iam_role.firehose_delivery.arn
    cluster_jdbcurl = var.enable_serverless ? "" : "jdbc:redshift://${module.redshift.cluster_endpoint}/${var.database_name}"
    username        = var.master_username
    password        = var.master_password
    data_table_name = "url_events"
    copy_options    = "JSON 'auto' TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'"
    
    data_table_columns = join(",", [
      "event_id",
      "timestamp",
      "url",
      "user_id", 
      "session_id",
      "user_agent",
      "ip_address",
      "referrer",
      "page_title",
      "event_type",
      "processing_time"
    ])

    s3_backup_mode = "Enabled"
    s3_backup_configuration {
      role_arn           = aws_iam_role.firehose_delivery.arn
      bucket_arn         = aws_s3_bucket.event_backup.arn
      prefix             = "url-events/"
      error_output_prefix = "errors/"
      buffer_size        = 5
      buffer_interval    = 300
      compression_format = "GZIP"
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = aws_lambda_function.event_enricher.arn
        }
      }
    }
  }

  tags = module.tags.tags
}

################################################################################
## Application Load Balancer for Event Collection
################################################################################

resource "aws_lb" "event_collector" {
  name               = "${var.namespace}-${var.environment}-${var.name}-collector"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = data.aws_subnets.public.ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "collector-logs"
    enabled = true
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-collector"
    }
  )
}

# Target group for event collection API
resource "aws_lb_target_group" "event_collector" {
  name        = "${var.namespace}-${var.environment}-event-collector"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "lambda"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-event-collector"
    }
  )
}

# HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.event_collector.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.event_collector.arn
  }

  tags = module.tags.tags
}

# HTTP listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.event_collector.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = module.tags.tags
}

################################################################################
## Lambda Functions
################################################################################

# Event collector Lambda
resource "aws_lambda_function" "event_collector" {
  filename         = "${path.module}/event_collector.zip"
  function_name    = "${var.namespace}-${var.environment}-${var.name}-event-collector"
  role            = aws_iam_role.lambda_event_collector.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  source_code_hash = data.archive_file.event_collector.output_base64sha256

  environment {
    variables = {
      KINESIS_STREAM_NAME = aws_kinesis_stream.url_events.name
      REGION             = var.region
    }
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-event-collector"
    }
  )
}

data "archive_file" "event_collector" {
  type        = "zip"
  output_path = "${path.module}/event_collector.zip"
  
  source {
    content  = file("${path.module}/event_collector.py")
    filename = "lambda_function.py"
  }
}

# Event enricher Lambda for Firehose processing
resource "aws_lambda_function" "event_enricher" {
  filename         = "${path.module}/event_enricher.zip"
  function_name    = "${var.namespace}-${var.environment}-${var.name}-event-enricher"
  role            = aws_iam_role.lambda_event_enricher.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.event_enricher.output_base64sha256

  environment {
    variables = {
      REGION = var.region
    }
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-event-enricher"
    }
  )
}

data "archive_file" "event_enricher" {
  type        = "zip"
  output_path = "${path.module}/event_enricher.zip"
  
  source {
    content  = file("${path.module}/event_enricher.py")
    filename = "lambda_function.py"
  }
}

# Lambda target group attachment
resource "aws_lb_target_group_attachment" "event_collector" {
  target_group_arn = aws_lb_target_group.event_collector.arn
  target_id        = aws_lambda_function.event_collector.arn
  depends_on       = [aws_lambda_permission.alb_invoke_event_collector]
}

resource "aws_lambda_permission" "alb_invoke_event_collector" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_collector.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.event_collector.arn
}

################################################################################
## S3 Buckets
################################################################################

resource "aws_s3_bucket" "event_backup" {
  bucket = "${var.namespace}-${var.environment}-${var.name}-event-backup"

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-event-backup"
    }
  )
}

resource "aws_s3_bucket_versioning" "event_backup" {
  bucket = aws_s3_bucket.event_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.namespace}-${var.environment}-${var.name}-alb-logs"

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-alb-logs"
    }
  )
}

################################################################################
## Security Groups
################################################################################

resource "aws_security_group" "alb" {
  name_prefix = "${var.namespace}-${var.environment}-${var.name}-alb-"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-alb-sg"
    }
  )
}

################################################################################
## KMS Key
################################################################################
resource "aws_kms_key" "streaming" {
  description             = "KMS key for URL event streaming encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-streaming-key"
    }
  )
}

resource "aws_kms_alias" "streaming" {
  name          = "alias/${var.namespace}-${var.environment}-${var.name}-streaming"
  target_key_id = aws_kms_key.streaming.key_id
}

################################################################################
## Redshift Module
################################################################################
module "redshift" {
  source = "../../"

  enable_serverless = var.enable_serverless

  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.private.ids

  database_name        = var.database_name
  master_username      = var.master_username
  master_password      = var.master_password
  manage_user_password = var.manage_user_password

  # Cluster configuration
  node_type       = var.node_type
  number_of_nodes = var.node_count
  cluster_type    = var.node_count > 1 ? "multi-node" : "single-node"

  # Serverless configuration
  namespace_name = var.namespace_name
  workgroup_name = var.workgroup_name
  base_capacity  = var.base_capacity
  max_capacity   = var.max_capacity

  encrypted  = true
  kms_key_id = aws_kms_key.streaming.arn

  skip_final_snapshot                 = var.skip_final_snapshot
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  allow_version_upgrade               = true
  automated_snapshot_retention_period = var.automated_snapshot_retention_period

  tags = module.tags.tags
}
