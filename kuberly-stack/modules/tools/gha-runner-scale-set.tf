# resource "helm_release" "gha-runner-scale-set-controller" {
#   name             = "gha-runner-scale-set-controller"
#   namespace        = "actions-runner-system"
#   create_namespace = true
#   repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
#   chart            = "gha-runner-scale-set-controller"
#   version          = "0.9.1"
# }

# resource "kubernetes_cluster_role" "custom_role" {
#   metadata {
#     name = "gha-runner-scale-set-controller-role"
#   }

#   rule {
#     api_groups = ["*"]
#     resources  = ["*"]
#     verbs      = ["*"]
#   }
#   depends_on = [helm_release.gha-runner-scale-set-controller]
# }

# resource "kubernetes_cluster_role_binding" "custom_role_binding" {
#   metadata {
#     name = "gha-runner-scale-set-controller-rolebinding"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "gha-runner-scale-set-controller-gha-rs-controller"
#     namespace = "actions-runner-system"
#   }

#   role_ref {
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.custom_role.metadata[0].name
#     api_group = "rbac.authorization.k8s.io"
#   }
#   depends_on = [kubernetes_cluster_role.custom_role]
# }

# resource "helm_release" "gha-runner-scale-set" {
#   name             = "gha-runner-scale-set"
#   namespace        = "actions-runners"
#   create_namespace = true
#   force_update     = false
#   repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
#   chart            = "gha-runner-scale-set"
#   version          = "0.9.1"
#   values           = [file("./values/gha-runner-scale-set.yaml")]
# }