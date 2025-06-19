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
