resource "aws_kms_key" "rds_kuberly" {
  description             = "RDS kuberly database KMS key"
  deletion_window_in_days = 10
}

resource "aws_kms_key" "rds_kuberly_replication" {
  count = var.aws_replication_region != "" ? 1 : 0

  description             = "RDS kuberly database replicated backups KMS key"
  deletion_window_in_days = 10

  provider = aws.replication
}