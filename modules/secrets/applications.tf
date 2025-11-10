resource "aws_secretsmanager_secret" "frontend" {
  name = "frontend"
}

resource "aws_secretsmanager_secret" "core_secrets" {
  name = "core-secrets"
}

resource "aws_secretsmanager_secret" "hub_secrets" {
  name = "hub-secrets"
}

resource "aws_secretsmanager_secret" "cloudflare" {
  name = "cloudflare-apikey"
}

resource "aws_secretsmanager_secret" "github" {
  name = "github-secret"
}