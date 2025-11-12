locals {
  bucket_name = var.environment == "prod" ? "kuberly-templates" : "${data.aws_caller_identity.current.account_id}-${var.environment}-kuberly-templates"
}

resource "aws_s3_bucket" "kuberly_cf_templates_bucket" {
  bucket = local.bucket_name

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "kuberly_cf_templates_bucket" {
  bucket = aws_s3_bucket.kuberly_cf_templates_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.kuberly_cf_templates_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.kuberly_cf_templates_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.kuberly_cf_templates_bucket.arn}/*"
      }
    ]
  })
  depends_on = [ aws_s3_bucket_public_access_block.allow_public ]
}
