# Automated AWS Application Deployment with Terraform, Ansible and Docker

## Overview

This project demonstrates an automated deployment of a Dockerized web application on a private Amazon EC2 instance using Terraform, Ansible, AWS Systems Manager, and GitHub Actions.

Terraform provisions the AWS infrastructure, while Ansible configures the private EC2 instance and deploys an nginx Docker container.

The application is exposed to the Internet only through an Application Load Balancer (ALB). The EC2 instance has no public IP address and does not require inbound SSH access.

GitHub Actions is used to automate both infrastructure deployment and application configuration.

---

## Architecture

```text
                           Internet
                              │
                           HTTP :80
                              │
                     ┌────────▼────────┐
                     │       ALB       │
                     │ Public Subnets  │
                     └────────┬────────┘
                              │
                           HTTP :80
                              │
                       ALB Security Group
                              │
                              ▼
                     ┌─────────────────┐
                     │   Private EC2   │
                     │                 │
                     │     Docker      │
                     │        │        │
                     │      nginx      │
                     │       :80       │
                     └────────┬────────┘
                              │
                             NAT
                              │
                           Internet
```

### Deployment Flow

```text
GitHub Actions
      │
      ├── Terraform
      │      │
      │      ▼
      │   AWS Infrastructure
      │
      └── Ansible
             │
             │ AWS Systems Manager
             ▼
        Private EC2
             │
             ▼
           Docker
             │
             ▼
           nginx
```

---

## Technologies

- AWS
  - Amazon VPC
  - Amazon EC2
  - Application Load Balancer
  - AWS Systems Manager
  - AWS IAM
  - Amazon S3
- Terraform
- Ansible
- Docker
- nginx
- GitHub Actions
- GitHub OIDC

---

## Infrastructure

Terraform provisions the following resources:

- VPC
- Two public subnets
- Two private subnets
- Internet Gateway
- NAT Gateway
- Route tables
- Application Load Balancer
- Target Group
- Private EC2 instance
- Security Groups
- IAM instance profile
- AWS Systems Manager VPC endpoints

The EC2 instance runs in a private subnet without a public IP address.

---

## Security Design

### Private EC2

The application server is deployed in a private subnet and does not have a public IP address.

No inbound SSH access is required.

Administrative and deployment access is performed through AWS Systems Manager.

```text
GitHub Actions Runner
        │
        │ Ansible
        ▼
AWS Systems Manager
        │
        ▼
   SSM Agent
        │
        ▼
   Private EC2
```

### Security Groups

The ALB accepts HTTP traffic from the Internet.

```text
Internet
   │
   │ TCP/80
   ▼
ALB Security Group
```

The EC2 instance accepts HTTP traffic only from the ALB Security Group.

```text
ALB Security Group
        │
        │ TCP/80
        ▼
EC2 Security Group
```

Direct Internet access to EC2 port 80 is not permitted.

### GitHub Actions Authentication

GitHub Actions authenticates to AWS using OpenID Connect (OIDC).

This allows GitHub Actions to obtain temporary AWS credentials without storing long-lived AWS access keys in the repository.

```text
GitHub Actions
      │
      │ OIDC token
      ▼
    AWS STS
      │
      │ AssumeRoleWithWebIdentity
      ▼
   IAM Role
      │
      ▼
Temporary AWS Credentials
```

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── terraform workflow
│       ├── ansible deployment workflow
│       ├── ansible connection test workflow
│       └── terraform destroy workflow
│
├── terraform/
│   ├── main.tf
│   ├── network.tf
│   ├── ec2.tf
│   ├── alb.tf
│   ├── security_group.tf
│   ├── iam.tf
│   ├── ssm_endpoint.tf
│   ├── variables.tf
│   ├── output.tf
│   └── terraform.tfvars.example
│
├── ansible/
│   ├── inventory.yml
│   └── docker_deploy.yml
│
├── .gitignore
└── README.md
```

---

# Deployment

## Prerequisites

Before deploying this project, prepare the following resources.

### Terraform Remote Backend

Create an S3 bucket for storing the Terraform remote state.

The backend bucket is created separately from the application infrastructure so that the state remains available independently of the application lifecycle.

Configure the Terraform backend to use the pre-created S3 bucket.

### GitHub OIDC IAM Role

Create an IAM role that can be assumed by GitHub Actions through GitHub OIDC.

Configure the repository variable:

```text
IAM_ROLE_ARN
```

The variable contains the ARN of the IAM role assumed by GitHub Actions.

### Ansible Transfer Bucket

Prepare an S3 bucket used by the Ansible AWS Systems Manager connection plugin for file/module transfer.

Configure the bucket name in the Ansible configuration or inventory as required.

---

## 1. Deploy the AWS Infrastructure

Push the Terraform configuration to the `main` branch.

The Terraform GitHub Actions workflow performs:

```text
terraform fmt
      ↓
terraform init
      ↓
terraform validate
      ↓
terraform plan
      ↓
terraform apply
```

Terraform creates the VPC, networking, ALB, private EC2 instance, IAM resources, and Systems Manager connectivity required by the application.

After deployment, obtain the EC2 instance ID:

```bash
terraform output -raw ec2_instance_id
```

---

## 2. Configure the Ansible Inventory

Add the EC2 instance ID created by Terraform to the Ansible inventory.

Example:

```yaml
all:
  hosts:
    app_server:
      ansible_host: <YOUR_INSTANCE_ID>
      ansible_connection: amazon.aws.aws_ssm
      ansible_aws_ssm_region: ap-northeast-1
      ansible_aws_ssm_bucket_name: <YOUR_BUCKET_NAME>
```

Ansible connects to the EC2 instance through AWS Systems Manager rather than SSH.

This means the GitHub-hosted runner does not require direct network connectivity to the EC2 private IP address.

---

## 3. Test the Ansible Connection

Run the Ansible connection test workflow.

The workflow uses:

```text
GitHub-hosted Runner
        │
        │ amazon.aws.aws_ssm
        ▼
AWS Systems Manager
        │
        ▼
Private EC2
```

The Ansible ping module verifies that Ansible can connect to the managed node and execute Python.

A successful result should show:

```text
ok=1
changed=0
unreachable=0
failed=0
```

---

## 4. Deploy Docker and nginx with Ansible

Run the Ansible deployment workflow.

The Ansible playbook:

1. Installs Docker
2. Starts and enables the Docker service
3. Pulls the nginx container image
4. Starts the nginx container
5. Publishes container port 80 on EC2 port 80

The deployment path is:

```text
GitHub Actions Runner
        │
        │ Ansible over SSM
        ▼
Private EC2
        │
        ▼
      Docker
        │
        ▼
      nginx :80
```

The playbook uses Ansible modules to manage the desired state of the EC2 instance and Docker container.

Re-running the playbook should not unnecessarily recreate resources that are already in the desired state.

---

## 5. Verify the Deployment

### Target Group Health Check

Confirm that the EC2 target is reported as healthy by the ALB Target Group.

A healthy target confirms that the ALB can reach the nginx application on EC2 port 80.

### Obtain the ALB DNS Name

```bash
terraform output -raw alb_dns_name
```

### End-to-End Test

Access the application through the public ALB endpoint:

```bash
curl http://<ALB_DNS_NAME>/
```

A successful nginx response verifies the complete application path:

```text
Internet
   │
   ▼
Application Load Balancer
   │
   ▼
Target Group
   │
   ▼
Private EC2
   │
   ▼
Docker
   │
   ▼
nginx
```

This confirms that the ALB listener, Target Group, Security Groups, network routing, EC2 instance, Docker container, and nginx application are functioning together.

---

## Infrastructure Cleanup

A dedicated GitHub Actions workflow is provided to destroy the application infrastructure after testing.

Run the Terraform destroy workflow manually from GitHub Actions when the environment is no longer required.

```text
GitHub Actions
      │
      ▼
Terraform Destroy Workflow
      │
      ▼
terraform destroy
      │
      ▼
Application Infrastructure Removed
```

The separately managed Terraform backend and GitHub OIDC resources are not part of the application infrastructure lifecycle.

This separation allows the environment to be created and destroyed repeatedly while retaining the Terraform state backend and CI/CD authentication configuration.

---

## Key Design Decisions

### Why use a private EC2 instance?

The application server does not need to be directly exposed to the Internet. Only the ALB is publicly accessible.

This reduces the exposed network surface of the EC2 instance.

### Why use AWS Systems Manager instead of SSH?

Systems Manager allows Ansible to configure the private EC2 instance without:

- A public IP address
- Inbound SSH access
- SSH private keys
- A bastion host

### Why separate Terraform and Ansible?

Terraform manages infrastructure resources such as networking, EC2, IAM, and the ALB.

Ansible manages the operating system and application configuration inside the EC2 instance.

```text
Terraform → Infrastructure
Ansible   → Server configuration
Docker    → Application runtime
```

This keeps infrastructure provisioning and application configuration as separate responsibilities.

### Why use GitHub OIDC?

GitHub OIDC provides temporary AWS credentials through AWS STS.

This avoids storing long-lived AWS access keys in GitHub Actions and provides a more appropriate authentication model for CI/CD workloads.

---

## Future Improvements

Potential improvements include:

- Automatically passing the Terraform EC2 instance ID to Ansible instead of manually updating the inventory
- Using dynamic Ansible inventory
- Adding HTTPS with AWS Certificate Manager
- Adding automated application health verification after deployment
- Separating development and production environments
- Applying stricter least-privilege IAM policies
