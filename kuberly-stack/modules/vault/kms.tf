resource "aws_kms_key" "vault" {
  description         = "Vault unseal KMS key"
  enable_key_rotation = true
  multi_region        = true
}
