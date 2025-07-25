# Basic Redshift Cluster Example

This example demonstrates how to create a basic Amazon Redshift cluster using the terraform-aws-arc-redshift module. It's a great starting point for users who are new to Redshift and want to deploy a simple cluster.

## Architecture

This example creates:

1. A Redshift cluster in an existing VPC
2. Security groups for the Redshift cluster
3. Subnet group for the Redshift cluster
4. Parameter group for the Redshift cluster
5. Snapshot schedule for automated backups
6. SSM parameters to store the master username and password

## Prerequisites

- AWS account with appropriate permissions
- Terraform installed
- AWS CLI configured
- An existing VPC with private subnets

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Review the plan:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. To destroy the resources:

```bash
terraform destroy
```

## Configuration

The main configuration parameters can be adjusted in `variables.tf`. Key variables include:

- `region`: AWS region to deploy resources
- `vpc_name_filter`: Filter to find your VPC
- `subnet_type_filter`: Filter to find your subnets
- `database_name`: Name of the database to create in the Redshift cluster
- `master_username`: Username for the master user
- `node_type`: Node type for the Redshift cluster
- `node_count`: Number of nodes in the Redshift cluster

## Connecting to Redshift

After deploying the cluster, you can connect to it using various SQL clients:

1. **Using the AWS Console**:
   - Go to the Redshift console
   - Select your cluster
   - Click on "Query editor" to run SQL queries

2. **Using a SQL Client (e.g., SQL Workbench/J, DBeaver)**:
   - Host: Use the `redshift_cluster_endpoint` output
   - Port: 5439
   - Database: Use the `database_name` variable (default: "analytics")
   - Username: Use the `master_username` variable (default: "admin")
   - Password: Retrieve from SSM Parameter Store using the `master_password_ssm_parameter` output

## Security Considerations

- The master password is automatically generated and stored in AWS SSM Parameter Store
- The cluster is deployed in private subnets for enhanced security
- Security groups are configured to allow access only from within the VPC
- Consider enabling encryption at rest for production deployments

## Next Steps

After deploying this basic example, you might want to:

1. Create tables and load data into your Redshift cluster
2. Set up ETL processes to load data from S3 or other sources
3. Configure monitoring and alerting for your cluster
4. Implement more advanced security features like encryption and IAM authentication
5. Explore the complete example which includes integrations with other AWS services

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_redshift"></a> [redshift](#module\_redshift) | ../.. | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.6 |

## Resources

| Name | Type |
|------|------|
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create in the Redshift cluster | `string` | `"analytics"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_manage_user_password"></a> [manage\_user\_password](#input\_manage\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `null` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Password for the master DB user. If null, a random password will be generated | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Username for the master user | `string` | `"admin"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Redshift cluster | `string` | `"analytics"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for the resources | `string` | `"arc"` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes in the Redshift cluster | `number` | `2` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Node type for the Redshift cluster | `string` | `"dc2.large"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_security_group_data"></a> [security\_group\_data](#input\_security\_group\_data) | (optional) Security Group data | <pre>object({<br/>    security_group_ids_to_attach = optional(list(string), [])<br/>    create                       = optional(bool, true)<br/>    description                  = optional(string, null)<br/>    ingress_rules = optional(list(object({<br/>      description              = optional(string, null)<br/>      cidr_block               = optional(string, null)<br/>      source_security_group_id = optional(string, null)<br/>      from_port                = number<br/>      ip_protocol              = string<br/>      to_port                  = string<br/>      self                     = optional(bool, false)<br/>    })), [])<br/>    egress_rules = optional(list(object({<br/>      description                   = optional(string, null)<br/>      cidr_block                    = optional(string, null)<br/>      destination_security_group_id = optional(string, null)<br/>      from_port                     = number<br/>      ip_protocol                   = string<br/>      to_port                       = string<br/>      prefix_list_id                = optional(string, null)<br/>    })), [])<br/>  })</pre> | <pre>{<br/>  "create": false<br/>}</pre> | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Redshift Serverless resourcesr security group name | `string` | `"Redshift-Serverless-sg"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_redshift_cluster_endpoint"></a> [redshift\_cluster\_endpoint](#output\_redshift\_cluster\_endpoint) | The connection endpoint for the Redshift cluster |
| <a name="output_redshift_cluster_id"></a> [redshift\_cluster\_id](#output\_redshift\_cluster\_id) | The ID of the Redshift cluster |
| <a name="output_redshift_endpoint"></a> [redshift\_endpoint](#output\_redshift\_endpoint) | The endpoint of the Redshift deployment (either cluster or serverless) |
<!-- END_TF_DOCS -->