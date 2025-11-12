resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = var.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = var.addon_vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    resources = {
      requests = {
        cpu = "15m"
        memory = "75Mi"
      }
      limits = {
        cpu = "15m"
        memory = "75Mi"
      }
    }
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
    }
    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [
          {
            labelSelector = {
              matchExpressions = [
                {
                  key = "k8s-app"
                  operator = "In"
                  values = ["aws-node"]
                }
              ]
            }
            topologyKey = "kubernetes.io/hostname"
          }
        ]
      }
    }
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = var.cluster_name
  addon_name        = "coredns"
  addon_version     = var.addon_coredns_version
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    resources = {
      requests = {
        cpu = "15m"
        memory = "75Mi"
      }
      limits = {
        cpu = "15m"
        memory = "75Mi"
      }
    }
    nodeSelector = {
      "karpenter.sh/capacity-type" = var.capacity_type_mode
      "kubernetes.io/arch" = "arm64"
    }
    tolerations = [
      {
        key = "CriticalAddonsOnly"
        operator = "Exists"
      },
      {
        effect = "NoSchedule"
        key = "node-role.kubernetes.io/control-plane"
      }
    ]
    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [
          {
            labelSelector = {
              matchExpressions = [
                {
                  key = "k8s-app"
                  operator = "In"
                  values = ["kube-dns"]
                }
              ]
            }
            topologyKey = "kubernetes.io/hostname"
          }
        ]
      }
    }
    topologySpreadConstraints = []
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.addon_kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"
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
  cluster_name      = var.cluster_name
  addon_name        = "eks-pod-identity-agent"
  addon_version     = var.addon_pod_identity_version
  resolve_conflicts_on_update = "OVERWRITE"
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
    tolerations = [
      {
        "key" : "CriticalAddonsOnly",
        "operator" : "Exists"
      },
      {
        "effect" : "NoSchedule",
        "key" : "node-role.kubernetes.io/control-plane"
      }
    ]
    nodeSelector = {
      "kubernetes.io/arch" = "arm64"
      "karpenter.sh/capacity-type" = var.capacity_type_mode
    }
  })
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_ebs_csi_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_update = "OVERWRITE"
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
      nodeSelector = {
        "karpenter.sh/capacity-type" = var.capacity_type_mode
        "kubernetes.io/arch" = "arm64"
      }
      tolerations = []
      affinity = {
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [
            {
              labelSelector = {
                matchExpressions = [
                  {
                    key = "app"
                    operator = "In"
                    values = ["ebs-csi-controller"]
                  }
                ]
              }
              topologyKey = "kubernetes.io/hostname"
            }
          ]
        }
      }
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
    }
  })
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = var.addon_efs_csi_version
  service_account_role_arn = aws_iam_role.efs_csi_driver.arn
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    controller = {
      replicaCount = 1
      resources = {
        requests = {
          cpu = "5m"
          memory = "32Mi"
        }
        limits = {
          cpu = "10m"
          memory = "64Mi"
        }
      }
      nodeSelector = {
        "karpenter.sh/capacity-type" = var.capacity_type_mode
        "kubernetes.io/arch" = "arm64"
      }
      tolerations = [
        {
          key = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          key = "efs.csi.aws.com/agent-not-ready"
          operator = "Exists"
        }
      ]
    }
    node = {
      resources = {
        requests = {
          cpu = "5m"
          memory = "32Mi"
        }
        limits = {
          cpu = "10m"
          memory = "64Mi"
        }
      }
    }
  })
}
