resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.16.3"
  values           = [templatefile("./values/cert-manager.yaml", {
    aws_zone       = var.aws_zone
  })]
}