locals {
  external_secrets_resources = {
    cpu    = var.environment == "prod" ? "50m" : "10m"
    memory = var.environment == "prod" ? "128Mi" : "64Mi"
  }

  external_secrets_capacity_type = var.environment == "prod" ? "on-demand" : "spot"
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = "0.13.0"
  create_namespace = true
  reset_values     = true

  values = [
    templatefile("./values/external-secrets.yaml", {
      resources = local.external_secrets_resources
      capacity_type = local.external_secrets_capacity_type
    })
  ]
}

resource "kubectl_manifest" "external_secrets_secret_store" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-store
  namespace: kuberly
  annotations:
    helm.sh/resource-policy: keep
spec:
  provider:
    aws:
      service: SecretsManager
      region: "${var.aws_region}"
      auth:
        jwt:
          serviceAccountRef:
            name: aws-service-account
YAML
  depends_on = [
    resource.helm_release.argocd,
    helm_release.external_secrets
  ]
}

resource "kubectl_manifest" "k8s_operators_secret_store" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: k8s-operators-secrets-store
  namespace: k8s-operators-system
  annotations:
    helm.sh/resource-policy: keep
spec:
  provider:
    aws:
      service: SecretsManager
      region: "${var.aws_region}"
      auth:
        jwt:
          serviceAccountRef:
            name: k8s-operators-service-account
YAML
  depends_on = [
    resource.helm_release.argocd,
    helm_release.external_secrets
  ]
}

resource "kubectl_manifest" "external_secrets_sa" {
    yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-service-account
  namespace: kuberly
  annotations:
    kubernetes.io/service-account.name: aws-service-account
    eks.amazonaws.com/role-arn: "${module.external_secrets_irsa_role.iam_role_arn}"
YAML

  depends_on = [
    resource.helm_release.argocd,
    resource.helm_release.external_secrets
  ]
}

resource "kubectl_manifest" "external_secrets_k8s_operators_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-operators-service-account
  namespace: k8s-operators-system
  annotations:
    kubernetes.io/service-account.name: k8s-operators-service-account
    eks.amazonaws.com/role-arn: "${module.external_secrets_irsa_role.iam_role_arn}"
YAML

  depends_on = [
    resource.helm_release.argocd,
    resource.helm_release.external_secrets
  ]
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name_prefix = "${var.cluster_name}-external-secrets-"
  policy      = data.aws_iam_policy_document.external_secrets.json
}

module "external_secrets_irsa_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5.0"
  role_name_prefix = "external-secrets-irsa-"

  role_policy_arns = {
    policy = aws_iam_policy.external_secrets.arn
  }

  oidc_providers = {
    opencost = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["kuberly:aws-service-account", "k8s-operators-system:k8s-operators-service-account"]
    }
  }
}