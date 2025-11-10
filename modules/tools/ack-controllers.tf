locals {
  ACK_SYSTEM_NAMESPACE = "ack-system"
  OCI_REPOSITORY_URL   = "oci://public.ecr.aws/aws-controllers-k8s/"
  CHART                = "%s-chart"

  managed_policies = flatten([
    for key, _ in var.ack_controllers : [
      for _, policy in split("\n", trimspace(data.http.managed_policy[key].response_body)) : {
        policy_arn = policy
        name       = "${key}-${policy}"
        role       = aws_iam_role.ack_controller_role.name
      } if can(data.http.managed_policy[key].response_body) && data.http.managed_policy[key].status_code == 200
    ]
  ])

  ack_resources = {
    cpu    = var.environment == "prod" ? "50m" : "20m"
    memory = var.environment == "prod" ? "128Mi" : "64Mi"
  }

  ack_capacity_type = "spot"
}

resource "null_resource" "ack_crds" {
  for_each = var.ack_controllers

  provisioner "local-exec" {
    command = "kubectl apply -k 'github.com/aws-controllers-k8s/${each.key}-controller/config/crd?ref=v${each.value.version}'"
  }

  triggers = {
    controller_version = var.ack_controllers[each.key].version
  }
}

resource "helm_release" "ack-controller" {
  for_each = var.ack_controllers

  name             = each.key
  namespace        = local.ACK_SYSTEM_NAMESPACE
  create_namespace = true

  repository          = local.OCI_REPOSITORY_URL
  chart               = format(local.CHART, each.key)
  version             = each.value.version
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  values = try([
    templatefile("./values/ack/${each.key}.yaml", {
      role_arn = aws_iam_role.ack_controller_role.arn
      aws_zone = var.aws_zone
      resources = local.ack_resources
      capacity_type = local.ack_capacity_type
    })
  ], [])

  dynamic "set" {
    for_each = each.value.sets != null ? each.value.sets : {}
    content {
      name  = set.key
      value = set.value
    }
  }
  depends_on = [null_resource.ack_crds, aws_iam_role.ack_controller_role]
}

data "http" "managed_policy" {
  for_each = var.ack_controllers
  url      = "https://raw.githubusercontent.com/aws-controllers-k8s/${each.key}-controller/main/config/iam/recommended-policy-arn"
}

data "http" "inline_policy" {
  for_each = var.ack_controllers
  url      = "https://raw.githubusercontent.com/aws-controllers-k8s/${each.key}-controller/main/config/iam/recommended-inline-policy"
}

resource "aws_iam_role" "ack_controller_role" {
  name = "ack-controller-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.cluster_oidc_provider_id}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        "StringEquals" = {
          "${var.cluster_oidc_provider_id}:aud": "sts.amazonaws.com",
          "${var.cluster_oidc_provider_id}:sub" = flatten([
            [
              for controller in keys(var.ack_controllers) :
              "system:serviceaccount:${local.ACK_SYSTEM_NAMESPACE}:ack-${controller}-controller"
            ],
            ["system:serviceaccount:k8s-operators-system:k8s-operators-controller-manager"],
            contains(keys(var.ack_controllers), "ecr") ? [
              "system:serviceaccount:clients-ci:default"
            ] : []
          ])
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.ack_controller_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "assume_policy" {
  name   = "ack-controller-assume-policy-${var.environment}"
  role   = aws_iam_role.ack_controller_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:AssumeRoleWithWebIdentity",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
