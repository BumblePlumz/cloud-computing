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
      iam        = local.localstack_url
      sts        = local.localstack_url
      lambda     = local.localstack_url
      apigateway = local.localstack_url
      dynamodb   = local.localstack_url
      logs       = local.localstack_url
    }
  }
}
