################################################################################
## RDS to Redshift Direct Streaming
## Change Data Capture (CDC) from RDS to Redshift without ETL tools
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
## RDS PostgreSQL Database with Logical Replication
################################################################################

# DB Subnet Group
resource "aws_db_subnet_group" "source_db" {
  name       = "${var.namespace}-${var.environment}-${var.name}-source-db-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-source-db-subnet-group"
    }
  )
}

# DB Parameter Group for Logical Replication
resource "aws_db_parameter_group" "source_db" {
  family = "postgres15"
  name   = "${var.namespace}-${var.environment}-${var.name}-source-db-params"

  # Enable logical replication
  parameter {
    name  = "wal_level"
    value = "logical"
  }

  parameter {
    name  = "max_wal_senders"
    value = "10"
  }

  parameter {
    name  = "max_replication_slots"
    value = "10"
  }

  parameter {
    name  = "max_logical_replication_workers"
    value = "10"
  }

  parameter {
    name  = "max_worker_processes"
    value = "16"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pg_logical"
  }

  # Performance optimization
  parameter {
    name  = "checkpoint_completion_target"
    value = "0.9"
  }

  parameter {
    name  = "wal_buffers"
    value = "16MB"
  }

  parameter {
    name  = "max_wal_size"
    value = "2GB"
  }

  tags = module.tags.tags
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "source_db" {
  identifier = "${var.namespace}-${var.environment}-${var.name}-source-db"

  # Engine configuration
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.rds_instance_class

  # Storage configuration
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds_streaming.arn

  # Database configuration
  db_name  = var.source_database_name
  username = var.rds_master_username
  password = var.rds_master_password
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.source_db.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.source_db.name

  # Backup configuration
  backup_retention_period = var.rds_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  delete_automated_backups = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds_streaming.arn

  # Deletion protection
  deletion_protection = var.enable_deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.namespace}-${var.environment}-${var.name}-final-snapshot"

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-source-db"
    }
  )
}

################################################################################
## DMS (Database Migration Service) for CDC
################################################################################

# DMS Subnet Group
resource "aws_dms_subnet_group" "main" {
  subnet_group_id = "${var.namespace}-${var.environment}-${var.name}-dms-subnet-group"
  subnet_ids      = data.aws_subnets.private.ids

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-dms-subnet-group"
    }
  )
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "main" {
  allocated_storage            = var.dms_allocated_storage
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  availability_zone           = data.aws_subnets.private.ids[0]
  engine_version              = var.dms_engine_version
  multi_az                    = var.dms_multi_az
  publicly_accessible         = false
  replication_instance_class  = var.dms_instance_class
  replication_instance_id     = "${var.namespace}-${var.environment}-${var.name}-dms-instance"
  replication_subnet_group_id = aws_dms_subnet_group.main.subnet_group_id

  vpc_security_group_ids = [aws_security_group.dms.id]

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-dms-instance"
    }
  )

  depends_on = [
    aws_dms_subnet_group.main
  ]
}

# DMS Source Endpoint (RDS PostgreSQL)
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.namespace}-${var.environment}-${var.name}-source-endpoint"
  endpoint_type = "source"
  engine_name   = "postgres"

  database_name = var.source_database_name
  username      = var.rds_master_username
  password      = var.rds_master_password
  port          = 5432
  server_name   = aws_db_instance.source_db.address

  ssl_mode = "require"

  postgres_settings {
    database_name               = var.source_database_name
    username                   = var.rds_master_username
    password                   = var.rds_master_password
    port                       = 5432
    server_name                = aws_db_instance.source_db.address
    ssl_mode                   = "require"
    
    # CDC specific settings
    slot_name                  = "dms_slot"
    plugin_name               = "pglogical"
    capture_ddls              = true
    max_file_size             = 512
    ddl_artifacts_schema      = "public"
    execute_timeout           = 60
    fail_tasks_on_lob_truncation = false
    heartbeat_enable          = true
    heartbeat_frequency       = 5
    heartbeat_schema          = "public"
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-source-endpoint"
    }
  )
}

# DMS Target Endpoint (Redshift)
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.namespace}-${var.environment}-${var.name}-target-endpoint"
  endpoint_type = "target"
  engine_name   = "redshift"

  database_name = var.database_name
  username      = var.master_username
  password      = var.master_password
  port          = 5439
  server_name   = var.enable_serverless ? "" : split(":", module.redshift.cluster_endpoint)[0]

  ssl_mode = "require"

  redshift_settings {
    database_name                     = var.database_name
    username                         = var.master_username
    password                         = var.master_password
    port                            = 5439
    server_name                     = var.enable_serverless ? "" : split(":", module.redshift.cluster_endpoint)[0]
    
    # Redshift specific settings
    bucket_name                     = aws_s3_bucket.dms_intermediate.bucket
    bucket_folder                   = "dms-data"
    service_access_role_arn         = aws_iam_role.dms_redshift_access.arn
    
    # Performance settings
    load_timeout                    = 900
    max_file_size                   = 1048576  # 1GB
    write_buffer_size              = 32768     # 32MB
    
    # Data handling
    accept_any_date                = true
    after_connect_script           = "SET search_path TO public"
    bucket_name                    = aws_s3_bucket.dms_intermediate.bucket
    case_sensitive_names           = false
    comp_update                    = true
    connection_timeout             = 60
    date_format                    = "YYYY-MM-DD"
    empty_as_null                  = true
    explicit_ids                   = false
    file_transfer_upload_streams   = 10
    replace_chars                  = " "
    replace_invalid_chars          = "?"
    time_format                    = "HH:MI:SS"
    trim_blanks                    = true
    truncate_columns              = false
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-target-endpoint"
    }
  )
}

# DMS Replication Task
resource "aws_dms_replication_task" "main" {
  migration_type           = "cdc"  # Change Data Capture
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  replication_task_id      = "${var.namespace}-${var.environment}-${var.name}-cdc-task"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn

  # Table mappings - define which tables to replicate
  table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = var.source_schema_name
          table-name  = "%"
        }
        rule-action = "include"
        filters = []
      },
      {
        rule-type = "transformation"
        rule-id   = "2"
        rule-name = "2"
        rule-target = "schema"
        object-locator = {
          schema-name = var.source_schema_name
        }
        rule-action = "rename"
        value = var.target_schema_name
      }
    ]
  })

  # Replication task settings
  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema                 = var.target_schema_name
      SupportLobs                  = true
      FullLobMode                  = false
      LobChunkSize                 = 0
      LimitedSizeLobMode          = true
      LobMaxSize                   = 32
      InlineLobMaxSize            = 0
      LoadMaxFileSize             = 0
      ParallelLoadThreads         = 0
      ParallelLoadBufferSize      = 0
      BatchApplyEnabled           = true
      TaskRecoveryTableEnabled    = false
      ParallelApplyThreads        = 0
      ParallelApplyBufferSize     = 0
      ParallelApplyQueuesPerThread = 0
    }
    
    FullLoadSettings = {
      TargetTablePrepMode          = "DROP_AND_CREATE"
      CreatePkAfterFullLoad        = false
      StopTaskCachedChangesApplied = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks          = 8
      TransactionConsistencyTimeout = 600
      CommitRate                   = 10000
    }
    
    Logging = {
      EnableLogging = true
      LogComponents = [
        {
          Id       = "TRANSFORMATION"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "SOURCE_UNLOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "TARGET_LOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        }
      ]
    }
    
    ControlTablesSettings = {
      historyTimeslotInMinutes = 5
      ControlSchema           = ""
      HistoryTimeslotInMinutes = 5
      HistoryTableEnabled     = true
      SuspendedTablesTableEnabled = true
      StatusTableEnabled      = true
    }
    
    StreamBufferSettings = {
      StreamBufferCount      = 3
      StreamBufferSizeInMB   = 8
      CtrlStreamBufferSizeInMB = 5
    }
    
    ChangeProcessingDdlHandlingPolicy = {
      HandleSourceTableDropped   = true
      HandleSourceTableTruncated = true
      HandleSourceTableAltered   = true
    }
    
    ErrorBehavior = {
      DataErrorPolicy                 = "LOG_ERROR"
      DataTruncationErrorPolicy      = "LOG_ERROR"
      DataErrorEscalationPolicy      = "SUSPEND_TABLE"
      DataErrorEscalationCount       = 0
      TableErrorPolicy               = "SUSPEND_TABLE"
      TableErrorEscalationPolicy     = "STOP_TASK"
      TableErrorEscalationCount      = 0
      RecoverableErrorCount          = -1
      RecoverableErrorInterval       = 5
      RecoverableErrorThrottling     = true
      RecoverableErrorThrottlingMax  = 1800
      RecoverableErrorStopRetryAfterThrottlingMax = true
      ApplyErrorDeletePolicy         = "IGNORE_RECORD"
      ApplyErrorInsertPolicy         = "LOG_ERROR"
      ApplyErrorUpdatePolicy         = "LOG_ERROR"
      ApplyErrorEscalationPolicy     = "LOG_ERROR"
      ApplyErrorEscalationCount      = 0
      ApplyErrorFailOnTruncationDdl  = false
      FullLoadIgnoreConflicts        = true
      FailOnTransactionConsistencyBreached = false
      FailOnNoTablesCaptured         = true
    }
    
    ChangeProcessingTuning = {
      BatchApplyPreserveTransaction  = true
      BatchApplyTimeoutMin          = 1
      BatchApplyTimeoutMax          = 30
      BatchApplyMemoryLimit         = 500
      BatchSplitSize               = 0
      MinTransactionSize           = 1000
      CommitTimeout                = 1
      MemoryLimitTotal             = 1024
      MemoryKeepTime               = 60
      StatementCacheSize           = 50
    }
  })

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-cdc-task"
    }
  )

  depends_on = [
    aws_dms_endpoint.source,
    aws_dms_endpoint.target
  ]
}

################################################################################
## S3 Bucket for DMS Intermediate Storage
################################################################################

resource "aws_s3_bucket" "dms_intermediate" {
  bucket = "${var.namespace}-${var.environment}-${var.name}-dms-intermediate"

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-dms-intermediate"
    }
  )
}

resource "aws_s3_bucket_versioning" "dms_intermediate" {
  bucket = aws_s3_bucket.dms_intermediate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_intermediate" {
  bucket = aws_s3_bucket.dms_intermediate.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.rds_streaming.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dms_intermediate" {
  bucket = aws_s3_bucket.dms_intermediate.id

  rule {
    id     = "dms_intermediate_lifecycle"
    status = "Enabled"

    expiration {
      days = 30  # Clean up intermediate files after 30 days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

################################################################################
## Lambda Functions for Data Transformation
################################################################################

# Lambda function for real-time data transformation
resource "aws_lambda_function" "data_transformer" {
  filename         = "${path.module}/data_transformer.zip"
  function_name    = "${var.namespace}-${var.environment}-${var.name}-data-transformer"
  role            = aws_iam_role.lambda_data_transformer.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.data_transformer.output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      REDSHIFT_ENDPOINT = var.enable_serverless ? (
        length(module.redshift.serverless_workgroup_endpoint) > 0 ? 
        module.redshift.serverless_workgroup_endpoint[0].address : ""
      ) : module.redshift.cluster_endpoint
      DATABASE_NAME         = var.database_name
      REDSHIFT_WORKGROUP   = var.enable_serverless ? module.redshift.serverless_workgroup_name : ""
      REDSHIFT_CLUSTER     = var.enable_serverless ? "" : module.redshift.cluster_identifier
      SOURCE_DATABASE_HOST = aws_db_instance.source_db.address
      SOURCE_DATABASE_NAME = var.source_database_name
      SOURCE_USERNAME      = var.rds_master_username
      SOURCE_PASSWORD      = var.rds_master_password
      KMS_KEY_ID          = aws_kms_key.rds_streaming.key_id
    }
  }

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-data-transformer"
    }
  )
}

data "archive_file" "data_transformer" {
  type        = "zip"
  output_path = "${path.module}/data_transformer.zip"
  
  source {
    content  = file("${path.module}/data_transformer.py")
    filename = "lambda_function.py"
  }
}

# EventBridge rule to trigger Lambda on DMS events
resource "aws_cloudwatch_event_rule" "dms_events" {
  name        = "${var.namespace}-${var.environment}-${var.name}-dms-events"
  description = "Capture DMS replication task events"

  event_pattern = jsonencode({
    source      = ["aws.dms"]
    detail-type = ["DMS Replication Task State Change"]
    detail = {
      state = ["running", "stopped", "failed"]
    }
  })

  tags = module.tags.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.dms_events.name
  target_id = "TriggerLambdaFunction"
  arn       = aws_lambda_function.data_transformer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_transformer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dms_events.arn
}

################################################################################
## KMS Key for Encryption
################################################################################
resource "aws_kms_key" "rds_streaming" {
  description             = "KMS key for RDS to Redshift streaming encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    module.tags.tags,
    {
      Name = "${var.namespace}-${var.environment}-${var.name}-rds-streaming-key"
    }
  )
}

resource "aws_kms_alias" "rds_streaming" {
  name          = "alias/${var.namespace}-${var.environment}-${var.name}-rds-streaming"
  target_key_id = aws_kms_key.rds_streaming.key_id
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
  kms_key_id = aws_kms_key.rds_streaming.arn

  skip_final_snapshot                 = var.skip_final_snapshot
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  allow_version_upgrade               = true
  automated_snapshot_retention_period = var.automated_snapshot_retention_period

  # Allow access from DMS and Lambda
  ingress_rules = [
    {
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
  ]

  tags = module.tags.tags
}
