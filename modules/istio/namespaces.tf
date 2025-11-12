locals {
  ambient_namespaces = ["kuberly", "grafana"]
}

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(local.ambient_namespaces)

  metadata {
    name = each.key
    labels = merge({
      name = each.key
      "istio.io/dataplane-mode" = "ambient"
      "namespace.oam.dev/env" = each.key == "kuberly" ? "syc-kuberly" : null
      "usage.oam.dev/control-plane" = each.key == "kuberly" ? "env" : null
    }, var.environment == "dev" ? {
      "namespace.oam.dev/target"    = each.key == "kuberly" ? "syc-local-kuberly" : null
      "usage.oam.dev/runtime"       = each.key == "kuberly" ? "target" : null
    } : {})
  }
}

resource "kubectl_manifest" "istio_waypoint_kuberly" {
  count = var.environment == "dev" ? 1 : 0

  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: "kuberly-istio-waypoint"
  namespace: "kuberly"
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
YAML

  depends_on = [kubernetes_namespace_v1.namespaces]
}

# resource "kubectl_manifest" "istio_waypoints" {
#   for_each = toset(local.ambient_namespaces)

#   yaml_body = <<YAML
# apiVersion: gateway.networking.k8s.io/v1beta1
# kind: Gateway
# metadata:
#   name: "${each.key}-istio-waypoint"
#   namespace: "${each.key}"
# spec:
#   gatewayClassName: istio-waypoint
#   listeners:
#   - name: mesh
#     port: 15008
#     protocol: HBONE
# YAML

#   depends_on = [kubernetes_namespace_v1.namespaces]
# }