resource "aws_codebuild_project" "this" {
  for_each = toset(var.codebuild_names)

  name          = each.value
  description   = "Build for ${each.value} Terragrunt infrastructure"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild_role[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/tech-images:codebuild-v0.0.3"
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value == "plan" ? "buildspec-plan.yml" : "buildspec-apply.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${each.value}-${var.environment}"
      status     = "ENABLED"
    }
  }

  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.private_subnets

    security_group_ids = [var.eks_primary_sg]
  }
}

resource "aws_cloudwatch_log_group" "this_log_group" {
  for_each = toset(var.codebuild_names)

  name              = "/aws/codebuild/${each.value}-${var.environment}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  for_each = toset(var.codebuild_names)

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = var.allowed_assume_role_users
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  for_each = toset(var.codebuild_names)

  name = "codebuild-${each.value}-${var.aws_region}"

  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role[each.key].json
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  for_each = toset(var.codebuild_names)

  role       = aws_iam_role.codebuild_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "codebuild_permissions" {
  for_each = toset(var.codebuild_names)

  name_prefix = "CodeBuild-${each.value}-permissions"
  description = "Policy for ${var.environment} CodeBuild ${each.value}"
  policy      = data.aws_iam_policy_document.codebuild_permissions[each.key].json
}

resource "aws_iam_role_policy_attachment" "codebuild_permissions_attachment" {
  for_each = toset(var.codebuild_names)

  role       = aws_iam_role.codebuild_role[each.key].name
  policy_arn = aws_iam_policy.codebuild_permissions[each.key].arn
}

data "aws_iam_policy_document" "codebuild_permissions" {
  for_each = toset(var.codebuild_names)

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${each.value}-${var.environment}",
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${each.value}-${var.environment}:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
    ]

    resources = [
      "arn:aws:codebuild:eu-central-1:${data.aws_caller_identity.current.account_id}:report-group/${each.value}-*",
    ]
  }
}
