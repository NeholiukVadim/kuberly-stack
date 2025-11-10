data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubectl" {
  host                   = try(var.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(var.cluster_certificate_authority_data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  load_config_file       = false
}
