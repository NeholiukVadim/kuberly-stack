# data "aws_secretsmanager_secret_version" "pritunl_secrets" {
#   count = var.environment == "dev" ? 1 : 0 
#   secret_id = var.pritunl_secret_arn
# }

# resource "kubernetes_namespace" "pritunl" {
#   count = var.environment == "dev" || var.environment == "prod" ? 0 : 1
  
#   metadata {
#     name = "pritunl"
#   }
# }

# resource "kubernetes_persistent_volume_claim" "mongodb_pritunl" {
#   count = var.environment == "dev" || var.environment == "prod"? 0 : 1
  
#   metadata {
#     name      = "mongodb-pritunl"
#     namespace = "pritunl"
#   }

#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "10Gi"
#       }
#     }
#     storage_class_name = "gp3"
#   }

#   depends_on = [kubernetes_namespace.pritunl]
# }

# resource "helm_release" "pritunl" {
#   count            = var.environment == "prod" ? 0 : 1
#   name             = "pritunl"
#   namespace        = "pritunl"
#   create_namespace = true
#   repository       = "oci://public.ecr.aws/n3h0s9r7"
#   chart            = "pritunl"
#   version          = "0.2.5"
#   reset_values     = true
#   depends_on = [kubernetes_namespace.pritunl]
#   values = [templatefile("./values/pritunl.yaml", {
#     root_password    = jsondecode(data.aws_secretsmanager_secret_version.pritunl_secrets[0].secret_string)["root_password"]
#     pritunl_password = jsondecode(data.aws_secretsmanager_secret_version.pritunl_secrets[0].secret_string)["pritunl_password"]
#     aws_zone         = var.aws_zone
#     image_registry   = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
#   })]
# }

# resource "kubectl_manifest" "istio_virtual_service_vpn" {
#   count = var.environment == "prod" ? 0 : 1
  
#   yaml_body = <<-YAML
#     apiVersion: networking.istio.io/v1beta1
#     kind: VirtualService
#     metadata:
#       name: vpn
#       namespace: pritunl
#     spec:
#       gateways:
#         - istio-system/external-gateway
#       hosts:
#         - "*"
#       tcp:
#         - match:
#             - port: 1194
#           route:
#             - destination:
#                 host: pritunl.pritunl.svc.cluster.local
#                 port:
#                   number: 1194
#         - match:
#             - port: 1195
#           route:
#             - destination:
#                 host: pritunl.pritunl.svc.cluster.local
#                 port:
#                   number: 1195
#   YAML

#   depends_on = [helm_release.pritunl]
# }