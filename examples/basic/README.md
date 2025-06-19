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
