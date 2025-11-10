resource "random_password" "redis_kuberly_user" {
  length           = 24
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "redis_default_user" {
  length           = 24
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_elasticache_user_group" "kuberly_redis_user_group" {
  engine        = "REDIS"
  user_group_id = "kuberly-${var.environment}"
  user_ids      = [aws_elasticache_user.default_redis_user.user_id]

  lifecycle {
    ignore_changes = [user_ids]
  }
}

resource "aws_elasticache_user" "kuberly_redis_user" {
  user_id       = "kuberly-${var.environment}"
  user_name     = "kuberly"
  access_string = "on ~* +@all"
  engine        = "REDIS"
  passwords     = ["${random_password.redis_kuberly_user.result}"]

  depends_on = [ random_password.redis_kuberly_user ]
}

resource "aws_elasticache_user" "default_redis_user" {
  user_id       = "kuberly-default"
  user_name     = "default"
  access_string = "on ~app::* -@all +@read +@hash +@bitmap +@geo -setbit -bitfield -hset -hsetnx -hmset -hincrby -hincrbyfloat -hdel -bitop -geoadd -georadius -georadiusbymember"
  engine        = "REDIS"
  passwords     = ["${random_password.redis_default_user.result}"]

  depends_on = [ random_password.redis_default_user ]
}

resource "aws_elasticache_user_group_association" "kuberly" {
  user_group_id = aws_elasticache_user_group.kuberly_redis_user_group.user_group_id
  user_id       = aws_elasticache_user.kuberly_redis_user.user_id

  depends_on = [ 
    aws_elasticache_user_group.kuberly_redis_user_group,
    aws_elasticache_user.kuberly_redis_user 
  ]
}

resource "aws_elasticache_subnet_group" "elasticache" {
  name       = var.environment
  subnet_ids = [var.vpc_private_subnet_ids[0]]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.environment}-redis"
  description                = "Replication group for ElastiCache Redis cluster"
  apply_immediately          = true
  auto_minor_version_upgrade = true
  multi_az_enabled           = var.redis_multi_az
  automatic_failover_enabled = var.redis_replicated
  engine_version             = var.redis_version
  node_type                  = var.redis_instance_type
  num_cache_clusters         = var.redis_replicated ? 2 : 1
  final_snapshot_identifier  = "final-snapshot-${var.environment}"
  maintenance_window         = "mon:02:00-mon:03:00"
  subnet_group_name          = aws_elasticache_subnet_group.elasticache.id
  snapshot_retention_limit   = 7
  snapshot_window            = "01:00-02:00"
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_id                  = aws_kms_key.redis_kuberly.arn

  user_group_ids = [
    aws_elasticache_user_group.kuberly_redis_user_group.id
  ]

  security_group_ids = [
    var.db_security_group
  ]

  security_group_names = []

  depends_on = [
    aws_kms_key.redis_kuberly,
    aws_elasticache_subnet_group.elasticache
  ]
}