resource "aws_secretsmanager_secret" "postgresql" {
  name = "postgresql"
}

locals {
  postgresql_strings = {
    POSTGRES_URL         = format("postgres://%s:%s@%s/%s?sslmode=disable", aws_db_instance.rds.username, urlencode(aws_db_instance.rds.password), aws_db_instance.rds.endpoint, aws_db_instance.rds.db_name),
    POSTGRESINVOICES_URL = format("postgresql+psycopg2://%s:%s@%s/invoices?sslmode=disable", aws_db_instance.rds.username, urlencode(aws_db_instance.rds.password), aws_db_instance.rds.endpoint),
    POSTGRESCMS_URL      = format("postgres://%s:%s@%s/cmsdb?sslmode=disable", aws_db_instance.rds.username, urlencode(aws_db_instance.rds.password), aws_db_instance.rds.endpoint),
    DB_URL               = format("postgresql+asyncpg://%s:%s@%s/pricing", aws_db_instance.rds.username, urlencode(aws_db_instance.rds.password), aws_db_instance.rds.endpoint)
  }
}

resource "aws_secretsmanager_secret_version" "postgresql_secret_version" {
  secret_id     = aws_secretsmanager_secret.postgresql.id
  secret_string = jsonencode((local.postgresql_strings))
}
