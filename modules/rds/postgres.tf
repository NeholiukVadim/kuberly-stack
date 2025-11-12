locals {
  postgres_version = var.rds_version
}

resource "aws_db_subnet_group" "db" {
  name       = var.environment
  subnet_ids = [var.vpc_private_subnet_ids[0], var.vpc_private_subnet_ids[2]]
}

resource "random_password" "rds" {
  length           = 24
  override_special = "!#$%&*()-_=+[]{}<>:?"

  lifecycle {
    ignore_changes = [ override_special, length ]
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage                     = 30
  max_allocated_storage                 = 100
  auto_minor_version_upgrade            = false
  db_subnet_group_name                  = aws_db_subnet_group.db.name
  availability_zone                     = local.availability_zone
  backup_retention_period               = 14
  deletion_protection                   = true
  delete_automated_backups              = false
  enabled_cloudwatch_logs_exports       = ["postgresql"]
  engine                                = "postgres"
  engine_version                        = local.postgres_version
  instance_class                        = var.rds_instance_type
  db_name                               = "kuberly"
  identifier                            = var.environment
  maintenance_window                    = "Mon:02:00-Mon:02:30"
  backup_window                         = "01:00-01:30"
  multi_az                              = var.rds_multi_az
  username                              = "kuberly"
  password                              = random_password.rds.result
  publicly_accessible                   = false
  storage_type                          = "gp3"
  storage_encrypted                     = true
  kms_key_id                            = aws_kms_key.rds_kuberly.arn
  // TODO: run a backup for sensitive envs only
  final_snapshot_identifier = "final-snapshot-${var.environment}-main"
  apply_immediately         = true

  vpc_security_group_ids = [
    var.db_security_group
  ]
}

resource "aws_db_instance_automated_backups_replication" "rds_replication" {
  count                  = var.aws_replication_region != "" ? 1 : 0
  source_db_instance_arn = aws_db_instance.rds.arn
  retention_period       = 14
  kms_key_id             = aws_kms_key.rds_kuberly_replication[0].arn

  provider = aws.replication
}