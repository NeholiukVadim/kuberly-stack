resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "kuberly-codepipeline-provisioning-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_access_block" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket_encryption" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.codepipeline_s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
