resource "helm_release" "secret_generator" {
  name       = "kubernetes-secret-generator"
  namespace  = "kubernetes-secret-generator"
  repository = "https://helm.mittwald.de"
  chart      = "kubernetes-secret-generator"
  version    = "3.4.0"
  
  create_namespace = true

  values = [
    yamlencode({
      secretLength = 24
      resources = {
        requests = {
          cpu    = "100m"
          memory = "400Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "400Mi"
        }
      }
      tolerations = [
        {
          key = var.environment == "prod" ? "on-demand" : "spot"
          value = "true"
          operator = "Equal"
          effect = "NoSchedule"
        }
      ]
      nodeSelector = {
        "karpenter.sh/capacity-type" = var.environment == "prod" ? "on-demand" : "spot"
        "kubernetes.io/arch" = "amd64"
      }
    })
  ]
}
