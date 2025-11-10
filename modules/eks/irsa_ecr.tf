locals {
  vela_sa_name      = "kubevela-vela-core"
  vela_sa_namespace = "vela-system"
}

module "kuberly_internal" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "kuberly-internal-${var.environment}-"

  role_policy_arns = {
    ECRAccess = aws_iam_policy.kuberly_internal.arn
    SESAccess = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
    EC2ContainerRegistryAccess = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kuberly:core", "kuberly:hub", "${local.vela_sa_namespace}:${local.vela_sa_name}", "eks-delete-system:eks-delete"]
    }
  }
}

resource "aws_iam_policy" "kuberly_internal" { 
  name_prefix = "kuberly-internal-${var.environment}-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["ecr:DescribeRepositories", "ecr:DeleteRepository", "ec2:DescribeRegions", "ecr:CreateRepository", "ec2:DescribeAvailabilityZones"]
        Effect = "Allow"
        Resource = ["*"]
      },
      {
        Action   = ["sts:AssumeRole"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}