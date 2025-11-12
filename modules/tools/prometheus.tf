locals {
  health_endpoint = var.environment == "prod" ? "https://kuberly.io/api/v1/health" : "https://dev.kuberly.io/api/v1/health"
}

resource "random_password" "grafana_password" {
  length           = 24
  special          = false
}

data "aws_secretsmanager_secret_version" "discord_webhook" {
  count = var.environment == "prod" ? 1 : 0
  secret_id = var.discord_webhook_secret_id
}

resource "aws_iam_policy" "сloud_watch_readonly_access" {
  name_prefix = "${var.cluster_name}-grafana_cloudwatch"
  description = "EKS grafana_cloudwatch policy for cluster ${var.cluster_name}"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "autoscaling:Describe*",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:Describe*",
          "logs:TestMetricFilter",
          "logs:FilterLogEvents",
          "sns:Get*",
          "sns:List*"
        ],
        Effect : "Allow",
        Resource : "*"
      }
    ]
  })
}

module "granafa_cloud_watch_irsa_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5.0"
  role_name_prefix = "grafana-cloudwatch-irsa-"

  role_policy_arns = {
    policy = aws_iam_policy.сloud_watch_readonly_access.arn
  }

  oidc_providers = {
    opencost = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["grafana:grafana"]
    }
  }
}

resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "68.3.2"
  values = var.environment == "dev" ? [templatefile("./values/kube-prometheus-stack-dev.yaml",
    {
      metrics_retention_period    = var.prometheus_retention_period
      storage_size                = var.prometheus_storage_size
      grafana_password            = random_password.grafana_password.result
      loki_password               = random_password.loki_password.result
      dns_domain                  = var.dns_domain
      aws_zone                    = var.aws_zone
      aws_region                  = var.aws_region
      grafana_cloudwatch_role_arn = module.granafa_cloud_watch_irsa_role.iam_role_arn
    })
  ] : [ templatefile("./values/kube-prometheus-stack-prod.yaml", {
    metrics_retention_period    = var.prometheus_retention_period
    storage_size                = var.prometheus_storage_size
    grafana_password            = random_password.grafana_password.result
    loki_password               = random_password.loki_password.result
    dns_domain                  = var.dns_domain
    aws_zone                    = var.aws_zone
    aws_region                  = var.aws_region
    grafana_cloudwatch_role_arn = module.granafa_cloud_watch_irsa_role.iam_role_arn
    discord_webhook_url         = jsondecode(data.aws_secretsmanager_secret_version.discord_webhook[0].secret_string)["discord_webhook_url"]
    kuberly_health_endpoint     = local.health_endpoint
  })]

  depends_on = [ random_password.loki_password, module.granafa_cloud_watch_irsa_role]
}

resource "aws_secretsmanager_secret" "grafana" {
  name = "grafana-secrets"
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = jsonencode({
    "GRAFANA_API_URL" = "http://admin:${random_password.grafana_password.result}@kube-prometheus-stack-grafana.grafana.svc.cluster.local:80/api"
  })
}

resource "helm_release" "prom-label-proxy" {
  name             = "prom-label-proxy"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prom-label-proxy"
  version          = "0.10.1"
  values           = [templatefile("./values/prom-label-proxy.yaml", {
    aws_zone       = var.aws_zone
  })]
}

resource "helm_release" "prometheus-blackbox-exporter" {
  count            = var.environment == "prod" ? 1 : 0
  name             = "prometheus-blackbox-exporter"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-blackbox-exporter"
  version          = "10.1.0"
  values           = [templatefile("./values/prometheus-blackbox-exporter.yaml", {
    aws_zone       = var.aws_zone
  })]
}

resource "kubernetes_config_map" "istio_dashboards" {
  metadata {
    name      = "grafana-istio-dashboards"
    namespace = "grafana"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "istio-control-plane-dashboard.json" = file("${path.module}/values/grafana-dashboards/istio-control-plane-dashboard.json")
    "istio-ztunnel-dashboard.json" = file("${path.module}/values/grafana-dashboards/istio-ztunnel-dashboard.json")
    "istio-mesh-dashboard.json" = file("${path.module}/values/grafana-dashboards/istio-mesh-dashboard.json")
    "istio-service-dashboard.json" = file("${path.module}/values/grafana-dashboards/istio-service-dashboard.json")
    "istio-workload-dashboard.json" = file("${path.module}/values/grafana-dashboards/istio-workload-dashboard.json")
    "RDS-dashboard.json" = file("${path.module}/values/grafana-dashboards/RDS-dashboard.json")
    "DocumentDB-dashboard.json" = file("${path.module}/values/grafana-dashboards/DocumentDB-dashboard.json")
    "Elasticache-dashboard.json" = file("${path.module}/values/grafana-dashboards/Elasticache-dashboard.json")
  }
}
