# WordPress with S3 Integration Automated deployment using Terraform

![Architecture](https://drive.google.com/uc?export=view&id=18593PBFvf1s_GlevaOEkZz8TuFxurGag)

### Overview
This Terraform project automates the deployment of a WordPress site integrated with Amazon S3 for media storage. It provisions the necessary AWS infrastructure, including VPCs, subnets, EC2 instances, and an S3 bucket, while configuring the WP Offload Media Lite plugin to offload media files to S3.

### Features
- **Infrastructure as Code (IaC)**: Fully automated deployment using Terraform.
- Software defined networking with AWS VPC, subnets, NAT gateways, and security groups.
- AWS IAM roles and policies for secure access to S3.
- Pre-configured Apache, PHP, and MariaDB for WordPress.
- Automated installation of the WP Offload Media Lite plugin.