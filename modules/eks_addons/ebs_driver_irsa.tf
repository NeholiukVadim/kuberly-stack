data "aws_iam_policy_document" "ebs_csi_driver_webidentity" {
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
        "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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

resource "aws_iam_role" "ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_webidentity.json
  name_prefix        = "${var.cluster_name}-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

