data "aws_iam_policy_document" "efs_csi_driver_webidentity" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:efs-csi-controller-sa"
      ]
    }

    principals {
      type = "Federated"

      identifiers = [
        var.cluster_oidc_provider_arn
      ]
    }
  }
}

resource "aws_iam_role" "efs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_webidentity.json
  name_prefix        = "${var.cluster_name}-efs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  role       = aws_iam_role.efs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

