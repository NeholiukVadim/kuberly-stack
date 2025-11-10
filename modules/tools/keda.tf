resource "helm_release" "keda" {
  namespace        = "keda"
  create_namespace = true

  name       = "keda"
  chart      = "keda"
  repository = "https://kedacore.github.io/charts"
  version    = "2.16.1"
  values     = [templatefile("./values/keda.yaml", {
    aws_zone           = var.aws_zone
  })]
}