locals {
  branch_name = var.environment == "prod" ? "prod" : "main"

  project_names_map = { "plan" = "plan", "apply" = "apply" }

  common_environment_variables = [
    {
      name  = "BITBUCKET_PASSWORD"
      value = var.codepipeline_secret_name
      type  = "SECRETS_MANAGER"
    },
    {
      name  = "WORKSPACE"
      value = var.environment == "prod" ? "prod" : "dev"
      type  = "PLAINTEXT"
    }
  ]

  environment_variables = jsonencode(local.common_environment_variables)
}

resource "aws_codepipeline" "codepipeline" {
  name     = "provisioning-v2"
  role_arn = aws_iam_role.codepipeline_role.arn

  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.codepipeline_s3_kms_key.key_id
      type = "KMS"
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [local.branch_name]
        }
        file_paths {
          excludes = ["helm/**"]
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.bitbucket.arn
        FullRepositoryId = "kuberly/infrastructure"
        BranchName       = local.branch_name
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.this[local.project_names_map["plan"]].name
        EnvironmentVariables = local.environment_variables
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.sns_approval.arn
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["plan_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.this[local.project_names_map["apply"]].name
        EnvironmentVariables = local.environment_variables
      }
    }
  }
}

resource "aws_codestarconnections_connection" "bitbucket" {
  name          = "kuberly"
  provider_type = "Bitbucket"
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-provisioning-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.bitbucket.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt"
    ]

    resources = [
      aws_kms_key.codepipeline_s3_kms_key.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.sns_approval.arn,
      "${aws_sns_topic.sns_approval.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_${var.environment}_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}
