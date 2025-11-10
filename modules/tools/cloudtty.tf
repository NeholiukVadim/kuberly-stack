locals {
  cloudtty_resources = {
    cpu    = var.environment == "prod" ? "100m" : "20m"
    memory = var.environment == "prod" ? "128Mi" : "24Mi"
  }

  cloudtty_capacity_type = var.environment == "prod" ? "on-demand" : "spot"
}

resource "helm_release" "cloudtty" {
  namespace        = "cloudtty"
  create_namespace = true

  name       = "cloudtty"
  chart      = "cloudtty"
  repository = "https://cloudtty.github.io/cloudtty"
  version    = "0.8.2"

  values = [
    templatefile("./values/cloudtty.yaml", {
      resources = local.cloudtty_resources
      capacity_type = local.cloudtty_capacity_type
    })
  ]
}

resource "kubernetes_cluster_role_binding" "cloudtty_binding" {
  metadata {
    name = "cloudtty"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "cloudtty"
  }

  depends_on = [ helm_release.cloudtty ]
}