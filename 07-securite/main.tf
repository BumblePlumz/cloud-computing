terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "use_localstack" {
  description = "true = LocalStack (dev), false = AWS réel (prod)"
  type        = bool
  default     = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# AWS Backup (vault + plan) n'est PAS supporté par LocalStack Community.
# Laisser à false en local ; passer à true sur LocalStack Pro ou AWS réel.
variable "enable_aws_backup" {
  description = "Active les ressources AWS Backup (Pro / AWS réel uniquement)"
  type        = bool
  default     = false
}

# La lifecycle configuration S3 ne se stabilise pas sur LocalStack Community
# (le provider attend une propagation jamais confirmée). false en local.
variable "enable_s3_lifecycle" {
  description = "Active la lifecycle S3 du bucket de backup (AWS réel)"
  type        = bool
  default     = false
}

# Le CloudWatch Dashboard renvoie une erreur 400 sur GetDashboard côté LocalStack
# (refresh Terraform en échec). false en local, true sur AWS réel.
variable "enable_dashboard" {
  description = "Active le CloudWatch Dashboard (AWS réel)"
  type        = bool
  default     = false
}

locals {
  localstack_url = "http://host.docker.internal:4566"
}

provider "aws" {
  region = var.aws_region

  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      kms        = local.localstack_url
      iam        = local.localstack_url
      s3         = local.localstack_url
      sts        = local.localstack_url
      logs       = local.localstack_url
      sns        = local.localstack_url
      cloudwatch = local.localstack_url
      ec2        = local.localstack_url
      backup     = local.localstack_url
    }
  }
}
