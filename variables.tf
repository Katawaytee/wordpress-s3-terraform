variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
}

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "wp-s3-6432001521"
}

variable "database_name" {
  description = "The name of the database"
  type        = string
  default     = "wordpress"
}

variable "database_user" {
  description = "The username for the database"
  type        = string
  default     = "username"
}

variable "database_pass" {
  description = "The password for the database user"
  type        = string
  default     = "password"
  sensitive   = true
}

variable "admin_user" {
  description = "The admin username for the application"
  type        = string
  default     = "admin"
}

variable "admin_pass" {
  description = "The admin password for the application"
  type        = string
  default     = "admin"
  sensitive   = true
}