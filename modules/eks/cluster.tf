# EKS module and dependent resources

locals {
  terraform_plan_role  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_plan_role_name}"
  terraform_apply_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_apply_role_name}"

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

  cluster_security_group_additional_rules = merge(
    {},
    var.environment == "prod" ? {
      ingress_vpn = {
        description          = "Allow VPN SG to access EKS API on 443"
        protocol             = "tcp"
        from_port            = 443
        to_port              = 443
        type                 = "ingress"
        source_security_group_id = var.vpn_instance_sg
      }
    } : {}
  )
  
  user_access_entries = {
    for username in var.eks_access_aws_iam_users["admins"] : username => {
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
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36.0"

  cluster_version                 = var.cluster_version
  cluster_name                    = var.environment
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = var.cluster_endpoint_public
  cluster_enabled_log_types       = []

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_ids

  iam_role_name                      = var.environment
  cluster_security_group_name        = var.environment
  cluster_security_group_description = "EKS cluster security group."
  prefix_separator                   = ""
  kms_key_administrators             = [local.terraform_plan_role, local.terraform_apply_role]

  enable_irsa               = true

  cluster_security_group_additional_rules = var.environment == "prod" ? local.cluster_security_group_additional_rules : {}

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
    terraform_plan = {
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
      principal_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_plan_role_name}"
      type            = "STANDARD"
    }

    terraform_apply = {
      policy_associations = {
          admin_policy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      principal_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_apply_role_name}"
      type            = "STANDARD"
    }
  }, local.user_access_entries)
}