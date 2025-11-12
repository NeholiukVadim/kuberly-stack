resource "aws_secretsmanager_secret" "bitbucket" {
  name        = "bitbucket"
  description = "Secret is used to access GIT repositories within build environments"
}
