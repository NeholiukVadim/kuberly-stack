resource "helm_release" "mysql_wordpress" {
  namespace         = "kuberly"
  name              = "mysql-wordpress"
  repository        = "oci://${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  chart             = "mysql"
  version           = "12.2.2"

  values = var.environment == "prod" ? [templatefile("./values/mysql-wordpress.yaml", {
    password       = random_password.mysql_wordpress.result
    aws_zone       = var.aws_zone
    image_registry = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  })] : [templatefile("./values/mysql-wordpress-dev.yaml", {
    password       = random_password.mysql_wordpress.result
    aws_zone       = var.aws_zone
    image_registry = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  })]
}

resource "random_password" "mysql_wordpress" {
  length  = 24
  special = false

  lifecycle {
    ignore_changes = [ special ]
  }
}

resource "random_password" "ftp_wordpress" {
  length  = 14
  numeric = false
  special = false
}

locals {
  ftp_wordpress_encoded_url = urlencode(random_password.ftp_wordpress.result)
}

resource "kubernetes_secret_v1" "ftp_wordpress" {
  metadata {
    name      = "ftp-wordpress"
    namespace = "kuberly"
  }

  data = {
    "FTP_PASSWORD" = local.ftp_wordpress_encoded_url
    "SFTP_USERS" = "daemon:${local.ftp_wordpress_encoded_url}:1001:1001"
  }
}

resource "kubernetes_persistent_volume_claim" "mysql_wordpress" {
  count = var.environment == "prod" ? 1 : 0
  metadata {
    name      = "mysql-wp"
    namespace = "kuberly"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "gp3"
  }
}