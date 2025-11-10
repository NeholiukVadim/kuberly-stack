output "codepipeline_secret_name" {
  value = aws_secretsmanager_secret.bitbucket.name
}

output "pritunl_secret_arn" {
  value = aws_secretsmanager_secret.pritunl_secrets.arn
}

output "discord_webhook_secret_id" {
  value = var.environment == "prod" ? aws_secretsmanager_secret.discord_webhook_url[0].id : ""
}