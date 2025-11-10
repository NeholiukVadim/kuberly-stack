# EKS module and dependent resources

locals {
  kuberly_manager_role  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.kuberly_manager_role}"

  node_security_group_additional_rules = {
    ingress_all = {
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_default = {
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      type                     = "ingress"
      self                     = true
    }
  }

  cluster_security_group_additional_rules = var.vpn_instance_sg != "" ? {
    ingress_vpn = {
      description          = "Allow VPN SG to access EKS API on 443"
      protocol             = "tcp"
      from_port            = 443
      to_port              = 443
      type                 = "ingress"
      source_security_group_id = var.vpn_instance_sg
    }
  } : {}
  
  user_access_entries = length(var.eks_access_iam_users) > 0 ? {
    for username in var.eks_access_iam_users : username => {
      policy_associations = {
          admin_policy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${username}"
      type          = "STANDARD"
    }
  } : {}
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.8.0"

  name               = var.environment
  kubernetes_version = var.cluster_version

  endpoint_public_access  = var.cluster_endpoint_public
  endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_ids

  iam_role_name = var.environment

  security_group_name        = var.environment
  security_group_description = "EKS cluster security group."
  security_group_additional_rules = local.cluster_security_group_additional_rules

  kms_key_administrators = [local.kuberly_manager_role]

  enable_irsa = true

  node_security_group_additional_rules = local.node_security_group_additional_rules

  authentication_mode = "API"

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.environment
  }

  fargate_profiles = {
    karpenter = {
      name = "karpenter"
      selectors = [
        {
          namespace = "karpenter"
        }
      ]
      subnet_ids = var.private_subnets_ids
    }
  }

  access_entries = merge({
    kuberly_manager = {
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
      principal_arn    = local.kuberly_manager_role
      type            = "STANDARD"
    }
  }, local.user_access_entries)
}