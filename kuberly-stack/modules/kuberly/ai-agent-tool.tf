module "ai-agent-tool" {
  source            = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version           = "~> 5.0"
  role_name_prefix  = "ai-agent-tool-"
  role_policy_arns  = {
    AdministratorAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
  oidc_providers = {
    main = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["kuberly:ai-agent-tool"]
    }
  }
}

resource "kubernetes_service_account_v1" "ai_agent_tool_sa" {
  metadata {
    name = "ai-agent-tool"
    namespace = "kuberly"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.ai-agent-tool.iam_role_arn}"
    }
  }

  depends_on = [ module.ai-agent-tool ]
}

resource "kubernetes_secret_v1" "ai_agent_tool_secret" {
  metadata {
    name      = "ai-agent-tool-secret"
    namespace = "kuberly"
  }

  data = {
    LOKI_ADDR   = "http://loki-query-frontend.monitoring.svc.cluster.local:3100"
    LOKI_ORG_ID = "admins"
    PROM_ADDR   = "http://prometheus-operated.monitoring.svc.cluster.local:9090"
    SERVICE_ACCOUNT_SECRET = base64encode(base64encode(sha256("admins-${var.environment}-service-account")))
  }

  type = "Opaque"

  depends_on = [kubernetes_service_account_v1.ai_agent_tool_sa]
}

resource "kubectl_manifest" "ai_agent_tool_oci_repository" {
  yaml_body = <<YAML
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: ai-agent-tool
  namespace: flux-system
spec:
  interval: 1m
  %{ if var.environment == "prod" } 
  url: oci://public.ecr.aws/z3d7d2e2/ai-agent-tool
  %{else}
  url: oci://public.ecr.aws/n3h0s9r7/ai-agent-tool
  %{ endif }
  provider: generic
  ref:
    %{ if var.environment == "prod" } 
    tag: 1.0.0-timoni-prod-hub
    %{else}
    tag: 1.0.0-timoni-dev-hub
    %{ endif }
YAML
  depends_on = [kubernetes_service_account_v1.ai_agent_tool_sa]
}

resource "kubectl_manifest" "ai_agent_tool_kustomization" {
  yaml_body = <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: ai-agent-tool
  namespace: flux-system
spec:
  force: false
  interval: 1h
  path: ./
  prune: true
  retryInterval: 30s
  sourceRef:
    kind: OCIRepository
    name: ai-agent-tool
  targetNamespace: kuberly
  timeout: 5m
  wait: true
YAML
  depends_on = [kubectl_manifest.ai_agent_tool_oci_repository]
}
