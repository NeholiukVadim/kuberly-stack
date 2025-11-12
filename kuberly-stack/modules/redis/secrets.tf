locals {
  redis_string = {
    REDIS_URL = aws_elasticache_replication_group.redis.primary_endpoint_address
  }
}

resource "aws_secretsmanager_secret" "redis" {
  name = "redis"
}

resource "aws_secretsmanager_secret_version" "redis_secret_version" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode(local.redis_string)
}