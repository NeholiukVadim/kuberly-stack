output "redis_primary_endpoint_address" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}