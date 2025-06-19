# AWS Redshift Terraform Module

This Terraform module creates either an Amazon Redshift cluster or Amazon Redshift Serverless resources based on configuration.

## Features

- Create a standard Amazon Redshift cluster with customizable configuration
- Create Amazon Redshift Serverless namespace and workgroup
- Toggle between standard cluster and serverless with a single boolean variable
- **Automatic password generation** - If no password is provided, a secure random password is generated
- **AWS Secrets Manager integration** - Option to let AWS manage passwords in Secrets Manager
- Security group management for both deployment options
- Subnet group creation for standard Redshift clusters
- Encryption configuration
- Snapshot management for standard clusters
- **Standardized tagging** using the sourcefuse/arc-tags/aws module

## Password Management

This module provides three options for managing the master user password:

1. **Random Password Generation (Recommended)**: Set `master_password = null` to automatically generate a secure random password
2. **Manual Password**: Provide your own password via the `master_password` variable
3. **AWS Secrets Manager**: Set `manage_user_password = true` to let AWS manage the password in Secrets Manager

```hcl
# Option 1: Random password generation
module "redshift" {
  source = "path/to/terraform-aws-arc-redshift"
  
  master_password = null  # Random password will be generated
  # Access the generated password via: module.redshift.redshift_master_password
}

# Option 2: Manual password
module "redshift" {
  source = "path/to/terraform-aws-arc-redshift"
  
  master_password = "YourStrongPassword123!"
}

# Option 3: AWS Secrets Manager
module "redshift" {
  source = "path/to/terraform-aws-arc-redshift"
  
  manage_user_password = true
}
```

## Usage

### Standard Redshift Cluster

```hcl
module "redshift" {
  source = "path/to/terraform-aws-arc-redshift"

  namespace   = "arc"
  environment = "dev"
  name        = "analytics"

  enable_serverless = false
  
  # Cluster configuration
  database_name     = "analytics"
  master_username   = "admin"
  master_password   = null  # Will generate a random password
  # master_password   = "YourStrongPassword123!"  # Or provide your own
  node_type         = "dc2.large"
  cluster_type      = "single-node"
  
  # Network configuration
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-12345678", "subnet-87654321"]
  publicly_accessible = false
  
  # Security
  encrypted         = true
  
  # Security group rules
  ingress_rules = [
    {
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
  
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  tags = {
    Project     = "Analytics"
    Department  = "Data"
  }
}
```

### Redshift Serverless

```hcl
module "redshift_serverless" {
  source = "path/to/terraform-aws-arc-redshift"

  namespace   = "arc"
  environment = "dev"
  name        = "analytics"

  enable_serverless = true
  
  # Serverless configuration
  database_name     = "analytics"
  master_username   = "admin"
  master_password   = null  # Will generate a random password
  # master_password   = "YourStrongPassword123!"  # Or provide your own
  base_capacity     = 32
  max_capacity      = 128
  
  # Network configuration
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-12345678", "subnet-87654321"]
  publicly_accessible = false
  
  # Security group rules
  ingress_rules = [
    {
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
  
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  tags = {
    Project     = "Analytics"
    Department  = "Data"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace | Namespace of the project | `string` | n/a | yes |
| environment | Name of the environment | `string` | n/a | yes |
| name | Name for the Redshift resources | `string` | n/a | yes |
| enable_serverless | Enable Redshift Serverless. If true, creates the serverless module; if false, creates the standard cluster module | `bool` | `false` | no |
| database_name | The name of the database to create | `string` | n/a | yes |
| master_username | Username for the master DB user | `string` | n/a | yes |
| master_password | Password for the master DB user. If null, a random password will be generated | `string` | `null` | no |
| manage_user_password | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `null` | no |
| vpc_id | ID of the VPC for Redshift | `string` | `null` | no |
| subnet_ids | List of subnet IDs for the Redshift subnet group | `list(string)` | `[]` | no |
| publicly_accessible | If true, the cluster can be accessed from a public network | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Standard Redshift Cluster Specific Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_identifier | The Cluster Identifier | `string` | `null` | no |
| node_type | The node type to be provisioned for the cluster | `string` | `"dc2.large"` | no |
| number_of_nodes | Number of nodes in the cluster | `number` | `1` | no |
| cluster_type | The cluster type to use. Either 'single-node' or 'multi-node' | `string` | `"single-node"` | no |
| skip_final_snapshot | Determines whether a final snapshot of the cluster is created before Redshift deletes it | `bool` | `false` | no |
| encrypted | If true, the data in the cluster is encrypted at rest | `bool` | `true` | no |

### Redshift Serverless Specific Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace_name | The name of the Redshift Serverless namespace | `string` | `null` | no |
| workgroup_name | The name of the Redshift Serverless workgroup | `string` | `null` | no |
| base_capacity | The base data warehouse capacity in Redshift Processing Units (RPUs) | `number` | `32` | no |
| max_capacity | The maximum data warehouse capacity in Redshift Processing Units (RPUs) | `number` | `512` | no |

## Outputs

### Standard Redshift Cluster Outputs

| Name | Description |
|------|-------------|
| redshift_cluster_endpoint | The connection endpoint for the Redshift cluster |
| redshift_cluster_id | The ID of the Redshift cluster |
| redshift_cluster_arn | The ARN of the Redshift cluster |
| redshift_cluster_security_group_id | The ID of the security group associated with the Redshift cluster |

### Redshift Serverless Outputs

| Name | Description |
|------|-------------|
| redshift_serverless_namespace_id | The ID of the Redshift Serverless namespace |
| redshift_serverless_namespace_arn | The ARN of the Redshift Serverless namespace |
| redshift_serverless_workgroup_id | The ID of the Redshift Serverless workgroup |
| redshift_serverless_workgroup_arn | The ARN of the Redshift Serverless workgroup |
| redshift_serverless_endpoint | The endpoint URL for the Redshift Serverless workgroup |
| redshift_serverless_security_group_id | The ID of the security group associated with the Redshift Serverless workgroup |

## License

This module is licensed under the MIT License.
