resource "aws_kms_key" "codepipeline_s3_kms_key" {
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "codepipeline_s3_kms_key_alias" {
  name          = "alias/codepipeline-${var.aws_region}-${var.environment}"
  target_key_id = aws_kms_key.codepipeline_s3_kms_key.key_id
}
