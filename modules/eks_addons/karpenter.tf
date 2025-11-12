module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.36.1"

  cluster_name                    = var.cluster_name
  create_access_entry             = true
  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.cluster_oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter_crd" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter-crd"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter-crd"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  version             = var.karpenter_version
  wait                = true

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "helm_release" "karpenter" {
  namespace         = "karpenter"
  create_namespace  = true
  name              = "karpenter"
  repository        = "oci://public.ecr.aws/karpenter"
  chart             = "karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  version           = var.karpenter_version

  values = [templatefile("./values/karpenter.yaml", {
    cluster_name     = var.cluster_name,
    cluster_endpoint = var.cluster_endpoint,
    queue_name       = module.karpenter.queue_name,
    iam_role_arn     = module.karpenter.iam_role_arn,
    image_registry   = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  })]

  depends_on = [helm_release.karpenter_crd]

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "kubectl_manifest" "node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
      namespace: karpenter
      labels:
        "type": "karpenter"
    spec:
      role: ${module.karpenter.node_iam_role_name}
      amiSelectorTerms:
      - alias: bottlerocket@${var.bottlerocket_version}
      kubelet:
        maxPods: 110
      blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          deleteOnTermination: true
          volumeSize: 30Gi
          volumeType: gp3
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${var.cluster_name}
      subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${var.cluster_name}
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2
        httpTokens: optional
      tags:
        type: karpenter
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "on_demand_node_pool" {
  yaml_body = templatefile("./nodepools/on-demand.yaml", {
    environment     = var.environment
    region          = var.region
    zones           = jsonencode(var.on_demand_zones)
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "on_demand_arm_node_pool" {
  yaml_body = templatefile("./nodepools/on-demand-arm.yaml", {
    environment     = var.environment
    region          = var.region
    zones           = jsonencode(var.on_demand_zones)
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "spot_node_pool" {
  yaml_body = templatefile("./nodepools/spot.yaml", {
    environment     = var.environment
    region          = var.region
    zones           = jsonencode(var.spot_zones)
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "spot_arm_node_pool" {
  yaml_body = templatefile("./nodepools/spot-arm.yaml", {
    environment     = var.environment
    region          = var.region
    zones           = jsonencode(var.spot_zones)
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "aws_iam_service_linked_role" "spot_iam_service_linked_role" {
  aws_service_name = "spot.amazonaws.com"
  description      = "Service linked role for EC2 spot instances"
  lifecycle {
    prevent_destroy = false
  }
}