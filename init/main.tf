provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "states_key" {
  description         = "Used for Terraform states S3 bucket encryption"
  enable_key_rotation = true
}

resource "aws_s3_bucket" "states_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-${var.environment}-tf-states"
}

resource "aws_s3_bucket_ownership_controls" "states_bucket_ownership" {
  bucket = aws_s3_bucket.states_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "states_bucket_versioning" {
  bucket = aws_s3_bucket.states_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "states_bucket_encryption" {
  bucket = aws_s3_bucket.states_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.states_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "states_bucket_public_access" {
  bucket = aws_s3_bucket.states_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
