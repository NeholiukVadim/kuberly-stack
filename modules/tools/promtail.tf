resource "helm_release" "promtail" {
  name             = "promtail"
  namespace        = "monitoring"
  create_namespace = true
  wait             = false
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  version          = "6.16.6"
  values           =  [ templatefile("./values/promtail.yaml", {
      loki_password = random_password.loki_password.result
    })
  ]

  depends_on = [ random_password.loki_password ]
}