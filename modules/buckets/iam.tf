# AWS IAM user related resources
data "aws_iam_user" "user" {
  for_each  = var.environment == "prod" ? [] : toset(var.aws_iam_users)
  user_name = each.key
}

# FTP review requirements
resource "aws_iam_account_password_policy" "password_policy" {
  minimum_password_length        = 14
  password_reuse_prevention      = 24
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}

resource "aws_iam_user" "devops_admin" {
  name = var.environment == "dev" ? "devops-admin-stage" : "devops-admin-${var.environment}"
}

resource "aws_iam_user_policy_attachment" "devops_admin_policy_attachment" {
  user       = aws_iam_user.devops_admin.name
  for_each   = var.devops_admin_policy_arns
  policy_arn = each.value
}

resource "aws_iam_policy" "enforce_mfa_policy" {
  name        = "DenyAllExceptListedIfNoMFA"
  description = "Deny all actions except listed if no MFA is present"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DenyAllExceptListedIfNoMFA",
        Effect = "Deny",
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "iam:ChangePassword",
          "sts:GetSessionToken",
        ],
        Resource = "*",
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false",
            "aws:ViaAWSService"          = "false",
          }
        }
      },
    ],
  })
}

resource "aws_iam_user_policy_attachment" "enforce_mfa_attachment" {
  user       = aws_iam_user.devops_admin.name
  policy_arn = aws_iam_policy.enforce_mfa_policy.arn
}
