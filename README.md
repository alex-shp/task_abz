# Deployment and Terraform Configuration Documentation

## Deployment Script (`wp_deploy.sh.tpl`)

### Configuration Options
The deployment script uses placeholders to define key configuration values for the WordPress setup. These placeholders are replaced dynamically during the deployment process:

| **Placeholder**    | **Description**                                          |
|---------------------|---------------------------------------------------------|
| `{{DB_HOST}}`       | Hostname or IP address of the database server.          |
| `{{DB_NAME}}`       | Name of the database used by WordPress.                 |
| `{{DB_USER}}`       | Username for accessing the WordPress database.          |
| `{{DB_PASSWORD}}`   | Password for accessing the WordPress database.          |
| `{{WP_URL}}`        | URL of the WordPress site.                              |

### Usage Instructions
1. Ensure the deployment tool is configured to replace placeholders with the correct values.
2. Process the template script using the deployment tool.
3. Execute the script manually or automatically as per the deployment workflow.

-----------------------------------------

## Terraform Module (`main.tf`)

### Description of Resources

#### Networking Resources
- **VPC**
  - **CIDR Block**: `10.0.0.0/16`
  - **DNS Support**: Enabled
  - **DNS Hostnames**: Enabled
  - **Resource Name**: `MyVPC`

- **Subnets**
  - **Public Subnets**: Two subnets in different availability zones:
    - CIDR: `10.0.1.0/24` (AZ: `eu-west-1a`)
    - CIDR: `10.0.4.0/24` (AZ: `eu-west-1b`)
  - **Private Subnets**: Two subnets in different availability zones:
    - CIDR: `10.0.2.0/24`
    - CIDR: `10.0.3.0/24`

- **Internet Gateway**: Attached to the VPC.
- **Route Tables**: Public and private route tables with appropriate associations.
- **NAT Gateway**: Enables private subnets to access the internet.

#### Compute Resources
- **EC2 Instances**
  - **Configuration**:
    - Two web servers in private subnets.
    - One bastion host in a public subnet (for SSH access).
  - **Instance Type**: `t2.micro`
  - **Provisioning**: User data script (`wp_deploy.sh.tpl`) for WordPress.

- **Load Balancer (ALB)**
  - **Accessibility**: Publicly accessible.
  - **Target Group**: EC2 instances.

#### Database Resources
- **RDS (MySQL)**
  - **Engine**: MySQL 8.0
  - **Instance Class**: `db.t3.micro`
  - **Database Name**: `wordpressdb`
  - **Subnet Group**: Private subnets.

#### Caching Resources
- **ElastiCache (Redis)**
  - **Node Type**: `cache.t2.micro`
  - **Subnet Group**: Private subnets.
  - **Security Group**: Internal traffic only.

#### Security Groups
| **Resource**    | **Rules**                                                    |
|------------------|-------------------------------------------------------------|
| **ALB**          | Allows HTTP (port 80) from anywhere.                        |
| **EC2**          | Allows traffic from ALB and SSH from the bastion host.      |
| **RDS**          | Allows internal traffic on port 3306.                       |
| **Redis**        | Allows internal traffic on port 6379.                       |
| **Bastion Host** | Allows SSH from any IP.                                     |

#### Outputs
- **ALB DNS Name**: Provides URL for the load balancer.
- **EC2 IPs**: Public and private IPs.
- **Database Endpoint**: RDS endpoint for WordPress.
- **Redis Endpoint**: Redis cache endpoint.

-----------------------------------------

## Troubleshooting Tips and Common Issues

### Deployment Script
| **Issue**                        | **Solution**                                                                               |
|-----------------------------------|-------------------------------------------------------------------------------------------|
| Permission denied                 | Ensure the script is executable: `chmod +x wp_deploy.sh`.                                 |
| Cannot connect to the database    | Verify placeholders are replaced with valid values.                                       |
| Debugging placeholder issues      | Add logs to confirm placeholder replacemen. Example: `echo "DB_HOST: {{DB_HOST}}"`.       |

### Terraform Module
| **Issue**                        | **Solution**                                                         |
|-----------------------------------|---------------------------------------------------------------------|
| Access denied                     | Verify AWS credentials and IAM permissions.                         |
| EC2 instance fails to init        | Check the startup script (User Data).                               |
| RDS instance not reachable        | Verify security group rules for port 3306.                          |
| Resource limit errors             | Check AWS quotas and request increases if needed.                   |
| ALB or EC2 not reachable          | Verify subnet, route table, and security group configurations.      |
| Debugging Terraform logs          | Enable debug logs: `export TF_LOG=DEBUG` and run `terraform apply`. |
