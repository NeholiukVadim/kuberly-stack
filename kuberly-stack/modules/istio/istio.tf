locals {
  istio_gw_replicas = var.environment == "prod" ? 2 : 1
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  chart            = "base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"
}

resource "helm_release" "istiod" {
  name             = "istiod"
  namespace        = "istio-system"
  chart            = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"
  wait             = true
  values           = [templatefile("values/istiod.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
  })]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "ingress_gateway" {
  name             = "ingress-gateway"
  namespace        = "istio-system"
  chart            = "gateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"
  values           = [templatefile("values/ingress-gateway.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
    replicas   = local.istio_gw_replicas
  })]

  depends_on = [helm_release.istiod]
}

resource "helm_release" "clients_gateway" {
  name             = "clients-gateway"
  namespace        = "istio-system"
  chart            = "gateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"
  values           = [templatefile("values/clients-gateway.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
    replicas   = local.istio_gw_replicas
  })]

  depends_on = [helm_release.istiod]
}

resource "helm_release" "internal_gateway" {
  name             = "internal-gateway"
  namespace        = "istio-system"
  chart            = "gateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"
  values           = var.environment == "dev" ? [templatefile("values/internal-gateway-dev.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
    replicas   = local.istio_gw_replicas
  })
  ] : [templatefile("values/internal-gateway.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
    replicas   = local.istio_gw_replicas
  })]

  depends_on = [helm_release.istiod]
}

resource "helm_release" "istio_cni" {
  name             = "istio-cni"
  namespace        = "istio-system"
  chart            = "cni"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"

  values           = [templatefile("values/istio-cni.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
  })]

  depends_on = [helm_release.istiod]
}

resource "helm_release" "ztunnel" {
  name             = "ztunnel"
  namespace        = "istio-system"
  chart            = "ztunnel"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  create_namespace = true
  version          = "1.27.2"

  values           = [templatefile("values/istio-ztunnel.yaml", {
    account_id = var.account_id
    aws_region = var.aws_region
  })]

  depends_on = [helm_release.istiod]
}

data "kubectl_file_documents" "gateway_api_crd" {
  content = file("crds/gateway-api.yaml")
}

resource "kubectl_manifest" "gateway_api_manifest" {
  for_each  = data.kubectl_file_documents.gateway_api_crd.manifests
  yaml_body = each.value
}

resource "kubectl_manifest" "ingress_gateway" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: external-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingress-gateway
  servers:
    - hosts:
      %{ if var.environment == "prod" }
        - "kuberly.io"
        - "*.kuberly.io"
        - "*.app.kuberly.io"
      %{ else }
        - "dev.kuberly.io"
        - "*.app.dev.kuberly.io"
      %{ endif }
      port:
        name: http
        number: 80
        protocol: HTTP
    - hosts:
      %{ if var.environment == "prod" }
        - "kuberly.io"
        - "*.kuberly.io"
        - "*.app.kuberly.io"
      %{ else }
        - "dev.kuberly.io"
        - "*.app.dev.kuberly.io"
      %{ endif }
      port:
        name: https
        number: 443
        protocol: HTTPS
      tls:
        credentialName: istio-kuberly-certs
        mode: SIMPLE
    - hosts:
        - '*'
      port:
        name: openvpn
        number: 1194
        protocol: TCP
    - hosts:
        - '*'
      port:
        name: openvpn-wp-sftp
        number: 1195
        protocol: TCP
YAML

  depends_on = [helm_release.ingress_gateway]
}

resource "kubectl_manifest" "internal_gateway" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: internal-gateway
  namespace: istio-system
spec:
  selector:
    istio: internal-gateway
  servers:
    - hosts:
        - '*'
      port:
        name: http
        number: 80
        protocol: HTTP
    - hosts:
        - '*'
      port:
        name: https
        number: 443
        protocol: HTTPS
      tls:
        mode: PASSTHROUGH
    %{ if var.environment == "dev" }
    - hosts:
        - '*'
      port:
        name: ssh
        number: 22
        protocol: TCP
    %{ endif }
YAML

  depends_on = [helm_release.internal_gateway]
}

resource "kubectl_manifest" "auth_deny_admin" {
  count = var.environment == "dev" || var.environment == "devops" ? 0 : 1
  yaml_body = <<YAML
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: kuberly
  namespace: istio-system
spec:
  action: DENY
  rules:
  - from:
    - source:
        notRemoteIpBlocks:
        - "${local.nat_ip}/32"
    to:
    - operation:
        ports: ["80", "443"]
        notPaths:
        - /wp-admin/admin-ajax.php
        - /wp-admin/admin-post.php
        paths:
        - /wp-admin*
        - /wp-login*
        - /wp-cron.php
        - /wp-json/wp/v2/users
YAML

  depends_on = [helm_release.istiod]
}
