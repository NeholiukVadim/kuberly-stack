resource "random_password" "loki_password" {
  length           = 24
  special          = false
}

resource "helm_release" "loki" {
  name             = "loki"
  namespace        = "monitoring"
  wait             = false
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "6.27.0"
  values           = [ templatefile("./values/loki.yaml", {
      loki_password         = random_password.loki_password.result
      loki_s3_role_arn      = aws_iam_role.loki_s3_role.arn
      loki_s3_bucket_region = aws_s3_bucket.loki_bucket.region
      loki_s3_bucket_name   = aws_s3_bucket.loki_bucket.bucket
      aws_zone              = var.aws_zone
    })
  ]

  depends_on = [ random_password.loki_password ]
}

resource "aws_s3_bucket" "loki_bucket" {
  bucket = "kuberly-loki-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "loki_access_block" {
  bucket = aws_s3_bucket.loki_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "loki_s3_policy" {
  name        = "LokiS3AccessPolicy-${var.environment}"
  description = "Policy that grants Loki access to S3 for storing logs"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.loki_bucket.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "loki_s3_role" {
  name               = "LokiS3AccessRole-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRoleWithWebIdentity"
        Effect    = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.cluster_oidc_provider_id}"
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_provider_id}:sub" = "system:serviceaccount:${helm_release.kube-prometheus-stack.namespace}:loki"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki_role_policy_attachment" {
  policy_arn = aws_iam_policy.loki_s3_policy.arn
  role       = aws_iam_role.loki_s3_role.name
}

resource "aws_s3_bucket_lifecycle_configuration" "loki_s3_lifecycle_policy" {
  bucket = aws_s3_bucket.loki_bucket.id

  rule {
    id     = "delete-old-admins-logs"
    status = "Enabled"

    filter {
      prefix = "admins/"
    }

    expiration {
      days = 7
    }
  }

  rule {
    id     = "delete-old-index-logs"
    status = "Enabled"

    filter {
      prefix = "index/"
    }

    expiration {
      days = 7
    }
  }

  rule {
    id     = "delete-old-self-monitoring-logs"
    status = "Enabled"

    filter {
      prefix = "self-monitoring/"
    }

    expiration {
      days = 7
    }
  }
}
