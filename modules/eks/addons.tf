resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = var.addon_vpc_cni_version

  configuration_values = jsonencode({
    init = {
      resources = {
        requests = {
          cpu = "5m"
          memory = "25Mi"
        }
        limits = {
          cpu = "5m"
          memory = "25Mi"
        }
      }
    }
    resources = {
      requests = {
        cpu = "15m"
        memory = "40Mi"
      }
      limits = {
        cpu = "15m"
        memory = "40Mi"
      }
    }
    nodeAgent = {
      resources = {
        requests = {
          cpu = "5m"
          memory = "20Mi"
        }
        limits = {
          cpu = "5m"
          memory = "20Mi"
        }
      }
    }
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
    }
    tolerations = [
      {
        "operator" : "Exists"
      }
    ]
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = var.addon_coredns_version

  configuration_values = jsonencode({
    resources = {
      requests = {
        cpu = "20m"
        memory = "50Mi"
      }
      limits = {
        cpu = "20m"
        memory = "50Mi"
      }
    }
    tolerations = [
      {
        "key" : "CriticalAddonsOnly",
        "operator" : "Exists"
      },
      {
        "effect" : "NoSchedule",
        "key" : "node-role.kubernetes.io/control-plane"
      },
      {
        "key" : "arch/arm",
        "value" : "true",
        "operator" : "Equal",
        "effect" : "NoSchedule"
      }
    ]
    nodeSelector = {
      "kubernetes.io/arch" = "arm64"
      "karpenter.sh/capacity-type" = "on-demand"
    }
  })

  depends_on = [
    module.eks.eks_managed_node_groups
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.addon_kube_proxy_version
  configuration_values = jsonencode({
    resources = {
      requests = {
        cpu = "30m"
        memory = "70Mi"
      }
      limits = {
        cpu = "30m"
        memory = "70Mi"
      }
    }
  })
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "eks-pod-identity-agent"
  addon_version     = var.addon_pod_identity_version
  configuration_values = jsonencode({
    resources = {
      requests = {
        cpu = "10m"
        memory = "20Mi"
      }
      limits = {
        cpu = "10m"
        memory = "20Mi"
      }
    }
  })
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_ebs_csi_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  configuration_values = jsonencode({
    controller = {
      replicaCount = 1
      resources = {
        requests = {
          cpu = "6m"
          memory = "30Mi"
        }
        limits = {
          cpu = "6m"
          memory = "30Mi"
        }
      }
      tolerations = [{
        key = "type"
        value = "karpenter"
        effect = "NoSchedule"
      }]
    }
    node = {
      resources = {
        requests = {
          cpu = "5m"
          memory = "25Mi"
        }
        limits = {
          cpu = "5m"
          memory = "25Mi"
        }
      }
      tolerations = [{
        key = "type"
        value = "karpenter"
        effect = "NoSchedule"
      }]
    }
  })

  depends_on = [
    module.eks.eks_managed_node_groups
  ]
}
