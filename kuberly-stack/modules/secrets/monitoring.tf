resource "aws_secretsmanager_secret" "discord_webhook_url" {
  count = var.environment == "prod" ? 1 : 0
  name        = "discord_webhook_url"
  description = "Secret is used to send messages to the Discord alert channel"
}