module "k8s-controller-manager" {
  source            = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version           = "~> 5.0"
  role_name_prefix  = "k8s-controller-manager-"
  role_policy_arns  = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["k8s-operators-system:k8s-operators-controller-manager"]
    }
  }
}

resource "aws_iam_role_policy" "assume_policy" {
  name   = "k8s-controller-manager-assume-policy"
  role   = module.k8s-controller-manager.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
