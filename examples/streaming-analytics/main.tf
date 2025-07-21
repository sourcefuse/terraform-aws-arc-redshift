################################################################################
## Streaming Analytics with Kinesis, Lambda, and Redshift
## This example demonstrates real-time data streaming architecture
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

################################################################################
## Kinesis Data Stream
################################################################################
resource "aws_kinesis_stream" "analytics_stream" {
  name             = "${var.namespace}-${var.environment}-${var.name}-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  shard_level_metrics = [
    "IncomingRecords",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = var.kinesis_stream_mode
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.streaming.arn

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-stream"
    }
  )
}

################################################################################
## Kinesis Data Firehose
################################################################################
resource "aws_kinesis_firehose_delivery_stream" "analytics_firehose" {
  name        = "${var.namespace}-${var.environment}-${var.name}-firehose"
  destination = "redshift"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.analytics_stream.arn
    role_arn          = aws_iam_role.firehose_delivery.arn
  }

  redshift_configuration {
    role_arn           = aws_iam_role.firehose_delivery.arn
    cluster_jdbcurl    = var.enable_serverless ? "" : "jdbc:redshift://${module.redshift.cluster_endpoint}/${var.database_name}"
    username           = var.master_username
    password           = var.master_password
    data_table_name    = "streaming_data"
    copy_options       = "JSON 'auto'"
    data_table_columns = "timestamp, event_type, user_id, data"

    s3_backup_mode     = "Enabled"
    s3_backup_configuration {
      role_arn           = aws_iam_role.firehose_delivery.arn
      bucket_arn         = aws_s3_bucket.firehose_backup.arn
      prefix             = "backup/"
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
          parameter_value = aws_lambda_function.stream_processor.arn
        }
      }
    }
  }

  tags = module.tags.tags
}

################################################################################
## S3 Buckets
################################################################################
resource "aws_s3_bucket" "firehose_backup" {
  bucket = "${var.namespace}-${var.environment}-${var.name}-firehose-backup"

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-firehose-backup"
    }
  )
}

resource "aws_s3_bucket_versioning" "firehose_backup" {
  bucket = aws_s3_bucket.firehose_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

################################################################################
## KMS Key
################################################################################
resource "aws_kms_key" "streaming" {
  description             = "KMS key for streaming analytics encryption"
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
## IAM Roles
################################################################################

# Firehose delivery role
resource "aws_iam_role" "firehose_delivery" {
  name = "${var.namespace}-${var.environment}-${var.name}-firehose-delivery"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = module.tags.tags
}

resource "aws_iam_role_policy" "firehose_delivery" {
  name = "${var.namespace}-${var.environment}-${var.name}-firehose-delivery"
  role = aws_iam_role.firehose_delivery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.firehose_backup.arn,
          "${aws_s3_bucket.firehose_backup.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.analytics_stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = aws_lambda_function.stream_processor.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.streaming.arn
      }
    ]
  })
}

# Lambda execution role
resource "aws_iam_role" "lambda_stream_processor" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-stream-processor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = module.tags.tags
}

resource "aws_iam_role_policy" "lambda_stream_processor" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-stream-processor"
  role = aws_iam_role.lambda_stream_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.analytics_stream.arn
      }
    ]
  })
}

################################################################################
## Lambda Function for Stream Processing
################################################################################
resource "aws_lambda_function" "stream_processor" {
  filename         = "${path.module}/stream_processor.zip"
  function_name    = "${var.namespace}-${var.environment}-${var.name}-stream-processor"
  role            = aws_iam_role.lambda_stream_processor.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.stream_processor.output_base64sha256

  environment {
    variables = {
      KINESIS_STREAM_NAME = aws_kinesis_stream.analytics_stream.name
    }
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-stream-processor"
    }
  )
}

data "archive_file" "stream_processor" {
  type        = "zip"
  output_path = "${path.module}/stream_processor.zip"
  
  source {
    content = file("${path.module}/stream_processor.py")
    filename = "lambda_function.py"
  }
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
