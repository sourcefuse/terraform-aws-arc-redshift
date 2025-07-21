################################################################################
## IAM Roles and Policies for URL Event Streaming
################################################################################

################################################################################
## Lambda Event Collector IAM Role
################################################################################

resource "aws_iam_role" "lambda_event_collector" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-event-collector"

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

resource "aws_iam_role_policy" "lambda_event_collector" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-event-collector"
  role = aws_iam_role.lambda_event_collector.id

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
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.url_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.streaming.arn
      }
    ]
  })
}

################################################################################
## Lambda Event Enricher IAM Role
################################################################################

resource "aws_iam_role" "lambda_event_enricher" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-event-enricher"

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

resource "aws_iam_role_policy" "lambda_event_enricher" {
  name = "${var.namespace}-${var.environment}-${var.name}-lambda-event-enricher"
  role = aws_iam_role.lambda_event_enricher.id

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
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.streaming.arn
      }
    ]
  })
}

################################################################################
## Kinesis Analytics IAM Role
################################################################################

resource "aws_iam_role" "kinesis_analytics" {
  name = "${var.namespace}-${var.environment}-${var.name}-kinesis-analytics"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })

  tags = module.tags.tags
}

resource "aws_iam_role_policy" "kinesis_analytics" {
  name = "${var.namespace}-${var.environment}-${var.name}-kinesis-analytics"
  role = aws_iam_role.kinesis_analytics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.url_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.processed_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.streaming.arn
      }
    ]
  })
}

################################################################################
## Kinesis Firehose Delivery IAM Role
################################################################################

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
          aws_s3_bucket.event_backup.arn,
          "${aws_s3_bucket.event_backup.arn}/*"
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
        Resource = aws_kinesis_stream.processed_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = aws_lambda_function.event_enricher.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.streaming.arn
      },
      {
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeClusterSubnetGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
## S3 Bucket Policies
################################################################################

# ALB logs bucket policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/collector-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/collector-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Event backup bucket policy
resource "aws_s3_bucket_policy" "event_backup" {
  bucket = aws_s3_bucket.event_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.firehose_delivery.arn
        }
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.event_backup.arn,
          "${aws_s3_bucket.event_backup.arn}/*"
        ]
      }
    ]
  })
}

################################################################################
## S3 Bucket Configurations
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "event_backup" {
  bucket = aws_s3_bucket.event_backup.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.streaming.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "event_backup" {
  bucket = aws_s3_bucket.event_backup.id

  rule {
    id     = "event_backup_lifecycle"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "alb_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

################################################################################
## CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "event_collector_logs" {
  name              = "/aws/lambda/${aws_lambda_function.event_collector.function_name}"
  retention_in_days = 14

  tags = module.tags.tags
}

resource "aws_cloudwatch_log_group" "event_enricher_logs" {
  name              = "/aws/lambda/${aws_lambda_function.event_enricher.function_name}"
  retention_in_days = 14

  tags = module.tags.tags
}

resource "aws_cloudwatch_log_group" "kinesis_analytics_logs" {
  name              = "/aws/kinesisanalytics/${aws_kinesis_analytics_application.event_processor.name}"
  retention_in_days = 14

  tags = module.tags.tags
}

################################################################################
## CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "kinesis_stream_incoming_records" {
  alarm_name          = "${var.namespace}-${var.environment}-${var.name}-kinesis-incoming-records"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "IncomingRecords"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors Kinesis stream incoming records"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.url_events.name
  }

  tags = module.tags.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.namespace}-${var.environment}-${var.name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.event_collector.function_name
  }

  tags = module.tags.tags
}

resource "aws_cloudwatch_metric_alarm" "firehose_delivery_errors" {
  alarm_name          = "${var.namespace}-${var.environment}-${var.name}-firehose-delivery-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DeliveryToRedshift.Records"
  namespace           = "AWS/KinesisFirehose"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors Firehose delivery errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.redshift_delivery.name
  }

  tags = module.tags.tags
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.namespace}-${var.environment}-${var.name}-alerts"

  tags = module.tags.tags
}
