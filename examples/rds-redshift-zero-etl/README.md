# RDS to Redshift Zero-ETL Integration Example

This example demonstrates how to set up AWS Zero-ETL integration between Amazon RDS PostgreSQL and Amazon Redshift using Terraform.

## What is Zero-ETL?

Zero-ETL is an AWS feature that allows you to replicate data from Amazon RDS to Amazon Redshift without building and maintaining ETL pipelines. It automatically replicates data changes from your RDS database to your Redshift data warehouse in near real-time, eliminating the need for custom ETL processes.

## Architecture

This example creates:

1. A VPC with public and private subnets
2. An Amazon RDS PostgreSQL instance (source database)
3. An Amazon Redshift cluster (target data warehouse)
4. IAM roles and policies for Zero-ETL integration
5. Zero-ETL integration between RDS and Redshift
6. External schema in Redshift to access RDS data

## Prerequisites

- AWS account with appropriate permissions
- Terraform installed (version 1.0.0 or later)
- AWS CLI configured
- The AWS region you're using must support Zero-ETL integrations

## Requirements for Zero-ETL

For Zero-ETL to work, your resources must meet these requirements:

### RDS PostgreSQL Requirements:
- Engine version: PostgreSQL 13.6 or higher
- Instance class: db.m5, db.m6i, db.r5, db.r6i, db.t3, or db.t4g
- Storage: Must be using gp2 or gp3 storage
- Binary logging must be enabled

### Redshift Requirements:
- Cluster type: RA3 nodes only (ra3.4xlarge, ra3.16xlarge, etc.)
- Must be in the same VPC as the RDS instance
- Must have at least 2 nodes for multi-node clusters

## Usage

### 1. Initialize Terraform

```bash
cd create
terraform init
```

### 2. Review and Apply the Configuration

```bash
terraform plan
terraform apply
```

### 3. Verify the Zero-ETL Integration

After the infrastructure is created, you can verify the integration:

1. Log in to the AWS Management Console
2. Navigate to Amazon Redshift
3. Select your cluster
4. Go to the "Query editor" tab
5. Connect to your database
6. Run a query to verify the external schema:




## References

- [AWS Documentation: Zero-ETL Integrations with Amazon Redshift](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/zero-etl.html)
- [AWS Blog: Simplify data integration with Zero-ETL](https://aws.amazon.com/blogs/big-data/simplify-data-integration-with-zero-etl-from-amazon-aurora-postgresql-to-amazon-redshift/)
- [SourceFuse ARC DB Module](https://github.com/sourcefuse/terraform-aws-arc-db)
- [AWS Redshift Terraform Module](https://github.com/sourcefuse/terraform-aws-arc-redshift)

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
| <a name="module_rds"></a> [rds](#module\_rds) | sourcefuse/arc-db/aws | 4.0.1 |
| <a name="module_redshift"></a> [redshift](#module\_redshift) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_rds_cluster_parameter_group.mysql_zerotetl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_rds_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_integration) | resource |
| [aws_redshift_resource_policy.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_resource_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the project | `string` | `"arc"` | no |
| <a name="input_rds_database_name"></a> [rds\_database\_name](#input\_rds\_database\_name) | Name of the RDS database | `string` | `"sourcedb"` | no |
| <a name="input_rds_master_password"></a> [rds\_master\_password](#input\_rds\_master\_password) | Master password for RDS | `string` | `null` | no |
| <a name="input_rds_master_username"></a> [rds\_master\_username](#input\_rds\_master\_username) | Master username for RDS | `string` | `"admin"` | no |
| <a name="input_redshift_database_name"></a> [redshift\_database\_name](#input\_redshift\_database\_name) | Name of the Redshift database | `string` | `"targetdb"` | no |
| <a name="input_redshift_master_password"></a> [redshift\_master\_password](#input\_redshift\_master\_password) | Master password for Redshift | `string` | `null` | no |
| <a name="input_redshift_master_username"></a> [redshift\_master\_username](#input\_redshift\_master\_username) | Master username for Redshift | `string` | `"admin"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Redshift Serverless resourcesr security group name | `string` | `"Redshift-Serverless-sg"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | <pre>{<br/>  "ManagedBy": "Terraform",<br/>  "Project": "RDS-to-Redshift-Zero-ETL"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
