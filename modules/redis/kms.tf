resource "aws_kms_key" "redis_kuberly" {
  multi_region            = true
  description             = "ElastiCache db cluster KMS key"
  deletion_window_in_days = 10
}