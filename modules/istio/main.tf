provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks",
        "get-token",
        "--region",
        var.aws_region,
        "--cluster-name",
        var.environment
      ]
      command = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      var.environment
    ]
    command = "aws"
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      var.cluster_name
    ]
    command = "aws"
  }
  load_config_file = false
}