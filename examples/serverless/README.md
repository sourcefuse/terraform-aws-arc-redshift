# Redshift Module Example

This example demonstrates how to use the Redshift module to deploy either a standard Redshift cluster or Redshift Serverless.

## Usage

### Initialize Terraform

```bash
terraform init
```

### Deploy Standard Redshift Cluster

```bash
terraform apply -var-file=dev.tfvars
```

### Deploy Redshift Serverless

```bash
terraform apply -var-file=dev.tfvars -var="enable_serverless=true"
```

### Clean Up Resources

```bash
terraform destroy -var-file=dev.tfvars
```

## Configuration

The module can be configured using the variables in `dev.tfvars`. The `enable_serverless` variable determines whether to deploy a standard Redshift cluster or Redshift Serverless.

### Common Configuration

- `database_name`: Name of the database to create
- `master_username`: Username for the master user
- `master_password`: Password for the master user

### Standard Redshift Configuration

Used when `enable_serverless = false`:

- `node_type`: Node type for the Redshift cluster
- `node_count`: Number of nodes in the Redshift cluster

### Serverless Redshift Configuration

Used when `enable_serverless = true`:

- `namespace_name`: Name of the Redshift Serverless namespace
- `workgroup_name`: Name of the Redshift Serverless workgroup
- `base_capacity`: Base capacity in Redshift Processing Units (RPUs)
- `max_capacity`: Maximum capacity in Redshift Processing Units (RPUs)

## Notes

- The module uses the same VPC and subnets for both deployment types
- KMS encryption is enabled by default for both deployment types
- The module creates supporting resources like S3 buckets and SSM parameters

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_redshift_serverless"></a> [redshift\_serverless](#module\_redshift\_serverless) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.3 |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automated_snapshot_retention_period"></a> [automated\_snapshot\_retention\_period](#input\_automated\_snapshot\_retention\_period) | The number of days to keep automated snapshots | `number` | `7` | no |
| <a name="input_base_capacity"></a> [base\_capacity](#input\_base\_capacity) | The base data warehouse capacity in Redshift Processing Units (RPUs) | `number` | `32` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create in the Redshift cluster | `string` | `"analytics"` | no |
| <a name="input_enable_encryption"></a> [enable\_encryption](#input\_enable\_encryption) | Whether to enable encryption at rest for the Redshift cluster | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Whether to enable logging to S3 for the Redshift cluster | `bool` | `true` | no |
| <a name="input_enable_maintenance"></a> [enable\_maintenance](#input\_enable\_maintenance) | Whether to enable automated maintenance via Lambda | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Whether to enable CloudWatch monitoring and alerts | `bool` | `true` | no |
| <a name="input_enable_s3_event_integration"></a> [enable\_s3\_event\_integration](#input\_enable\_s3\_event\_integration) | Whether to enable S3 event notifications to trigger Lambda for data loading | `bool` | `false` | no |
| <a name="input_enable_s3_integration"></a> [enable\_s3\_integration](#input\_enable\_s3\_integration) | Whether to enable S3 integration for data loading | `bool` | `true` | no |
| <a name="input_enable_serverless"></a> [enable\_serverless](#input\_enable\_serverless) | Whether to enable Redshift Serverless. If true, creates the serverless module; if false, creates the standard cluster module. | `bool` | `false` | no |
| <a name="input_enable_zero_etl"></a> [enable\_zero\_etl](#input\_enable\_zero\_etl) | Whether to enable Zero-ETL integration | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_manage_user_password"></a> [manage\_user\_password](#input\_manage\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `null` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the master DB user. If null, a random password will be generated | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Username for the master user | `string` | `"admin"` | no |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | The maximum data warehouse capacity in Redshift Processing Units (RPUs) | `number` | `128` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Redshift cluster | `string` | `"analytics"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the resources | `string` | `"arc"` | no |
| <a name="input_namespace_name"></a> [namespace\_name](#input\_namespace\_name) | The name of the Redshift Serverless namespace | `string` | `null` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes in the Redshift cluster | `number` | `1` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Node type for the Redshift cluster | `string` | `"dc2.large"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project for tagging | `string` | `"data-platform"` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | If true, the cluster can be accessed from a public network | `bool` | `false` | no |
| <a name="input_redshift_target_table"></a> [redshift\_target\_table](#input\_redshift\_target\_table) | Name of the target table in Redshift for data loading | `string` | `"public.events"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_s3_filter_prefix"></a> [s3\_filter\_prefix](#input\_s3\_filter\_prefix) | Prefix filter for S3 event notifications | `string` | `"data/"` | no |
| <a name="input_s3_filter_suffix"></a> [s3\_filter\_suffix](#input\_s3\_filter\_suffix) | Suffix filter for S3 event notifications | `string` | `".csv"` | no |
| <a name="input_security_group_data"></a> [security\_group\_data](#input\_security\_group\_data) | (optional) Security Group data | <pre>object({<br/>    security_group_ids_to_attach = optional(list(string), [])<br/>    create                       = optional(bool, true)<br/>    description                  = optional(string, null)<br/>    ingress_rules = optional(list(object({<br/>      description              = optional(string, null)<br/>      cidr_block               = optional(string, null)<br/>      source_security_group_id = optional(string, null)<br/>      from_port                = number<br/>      ip_protocol              = string<br/>      to_port                  = string<br/>      self                     = optional(bool, false)<br/>    })), [])<br/>    egress_rules = optional(list(object({<br/>      description                   = optional(string, null)<br/>      cidr_block                    = optional(string, null)<br/>      destination_security_group_id = optional(string, null)<br/>      from_port                     = number<br/>      ip_protocol                   = string<br/>      to_port                       = string<br/>      prefix_list_id                = optional(string, null)<br/>    })), [])<br/>  })</pre> | <pre>{<br/>  "create": false<br/>}</pre> | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Redshift Serverless resourcesr security group name | `string` | `"Redshift-Serverless-sg"` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final snapshot of the cluster is created before Redshift deletes it | `bool` | `false` | no |
| <a name="input_tables_excluded"></a> [tables\_excluded](#input\_tables\_excluded) | List of tables to exclude from the Zero-ETL integration | `list(string)` | `[]` | no |
| <a name="input_tables_included"></a> [tables\_included](#input\_tables\_included) | List of tables to include in the Zero-ETL integration | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | <pre>{<br/>  "Environment": "Development",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "Data Platform"<br/>}</pre> | no |
| <a name="input_workgroup_name"></a> [workgroup\_name](#input\_workgroup\_name) | The name of the Redshift Serverless workgroup | `string` | `null` | no |
| <a name="input_zero_etl_source_arn"></a> [zero\_etl\_source\_arn](#input\_zero\_etl\_source\_arn) | ARN of the source database for Zero-ETL integration | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The ID of the KMS key used for encryption |
| <a name="output_serverless_namespace_arn"></a> [serverless\_namespace\_arn](#output\_serverless\_namespace\_arn) | The ARN of the Redshift Serverless namespace |
| <a name="output_serverless_namespace_id"></a> [serverless\_namespace\_id](#output\_serverless\_namespace\_id) | The ID of the Redshift Serverless namespace |
| <a name="output_serverless_workgroup_arn"></a> [serverless\_workgroup\_arn](#output\_serverless\_workgroup\_arn) | The ARN of the Redshift Serverless workgroup |
<!-- END_TF_DOCS -->