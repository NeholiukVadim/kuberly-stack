resource "aws_secretsmanager_secret" "k8s_operators" {
  name = "k8s-operators-secrets"
}
