resource "helm_release" "tempo" {
  name             = "tempo"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo-distributed"
  version          = "1.32.0"
  values           = [templatefile("./values/tempo.yaml", {
      aws_zone     = var.aws_zone
    })
  ]
}