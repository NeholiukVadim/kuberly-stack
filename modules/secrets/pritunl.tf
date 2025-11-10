resource "random_password" "mongodb_password" {
  length  = 16
  special = false
}

resource "random_password" "setup_key" {
  length  = 16
  special = false
}

resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_password" "pritunl_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "pritunl_secrets" {
  name = "pritunl-passwords"
}

resource "aws_secretsmanager_secret_version" "pritunl_secrets" {
  secret_id = aws_secretsmanager_secret.pritunl_secrets.id
  secret_string = jsonencode({
    mongodb_uri      = "mongodb://pritunl:${random_password.mongodb_password.result}@mongodb-0.mongodb-headless.mongodb.svc.cluster.local:27017/pritunl?authSource=admin"
    setup_key        = random_password.setup_key.result
    root_password    = random_password.root_password.result
    pritunl_password = random_password.pritunl_password.result
  })
}
