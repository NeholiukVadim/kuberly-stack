data "aws_iam_policy_document" "vault_irsa" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*",
      "sts:AssumeRole"
    ]
    resources = [aws_kms_key.vault.arn]
  }
}

resource "aws_iam_policy" "vault_irsa" {
  name_prefix = "vault-irsa-"

  policy = data.aws_iam_policy_document.vault_irsa.json
}

module "vault_irsa_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version          = "~> 5.0"
  role_name_prefix = "vault-irsa-"

  role_policy_arns = {
    policy = aws_iam_policy.vault_irsa.arn
  }

  oidc_providers = {
    vault = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["vault:vault"]
    }
  }
}
