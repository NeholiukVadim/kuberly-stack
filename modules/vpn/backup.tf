resource "aws_iam_role" "dlm" {
  count = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  name_prefix = "${var.environment}-dlm-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "dlm" {
  count = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  name = "${var.environment}-dlm-"
  role = aws_iam_role.dlm[0].id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

resource "aws_dlm_lifecycle_policy" "this" {
  count              = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  description        = "${var.environment}-vpn"
  execution_role_arn = aws_iam_role.dlm[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]

    schedule {
      name = "daily"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["01:00"]
      }

      retain_rule {
        count = var.environment == "prod" ? 14 : 7
      }

      copy_tags = false
    }
    
    target_tags = {
      backup = "true"
    }
  }
}