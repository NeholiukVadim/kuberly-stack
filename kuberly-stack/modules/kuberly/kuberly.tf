resource "kubernetes_namespace_v1" "k8_operators_system" {

  metadata {
    name = "k8s-operators-system"
  }
}

resource "kubernetes_namespace_v1" "eks_delete_system" {

  metadata {
    name = "eks-delete-system"
  }
}

resource "kubernetes_service_account_v1" "k8s_operators_controller_sa" {
  metadata {
    name = "k8s-operators-controller-manager"
    namespace = "${kubernetes_namespace_v1.k8_operators_system.metadata.0.name}"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${var.k8s_operators_sa_role_arn}"
    }
  }

  depends_on = [
    kubernetes_namespace_v1.k8_operators_system
  ]
}

resource "kubernetes_service_account_v1" "eks_delete_system_sa" {
  metadata {
    name = "eks-delete"
    namespace = "${kubernetes_namespace_v1.eks_delete_system.metadata.0.name}"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${var.eks_delete_system_sa_role_arn}"
    }
  }

  depends_on = [
    kubernetes_namespace_v1.eks_delete_system
  ]
}

resource "kubernetes_cluster_role_binding" "cluster_admin_binding" {
  count = var.environment == "dev" ? 0 : 1
  metadata {
    name = "hub-cluster-admin-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "hub"
    namespace = "kuberly"
  }
}

resource "kubernetes_cluster_role_binding" "cloudtty_binding" {
  count = var.environment != "prod" ? 1 : 0
  metadata {
    name = "cloudtty"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "cloudtty"
  }
}

resource "kubernetes_cluster_role" "eks_delete_ack_access" {
  metadata {
    name = "eks-delete-ack-access"
  }

  rule {
    api_groups = ["ec2.services.k8s.aws"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["eks.services.k8s.aws"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["iam.services.k8s.aws"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "eks_delete_ack_access" {
  metadata {
    name = "eks-delete-ack-access"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.eks_delete_ack_access.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.eks_delete_system_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.eks_delete_system_sa.metadata[0].namespace
  }
}
