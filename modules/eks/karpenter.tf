module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.36.0"

  cluster_name                    = module.eks.cluster_name
  create_access_entry             = true
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
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
  version             = "1.6.3"
  wait                = true

  depends_on = [module.eks.eks_managed_node_groups]
}

resource "helm_release" "karpenter" {
  namespace         = "karpenter"
  create_namespace  = true
  name              = "karpenter"
  repository        = "oci://public.ecr.aws/karpenter"
  chart             = "karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  version           = "1.6.3"

  values = [templatefile("./values/karpenter.yaml", {
    cluster_name     = module.eks.cluster_name,
    cluster_endpoint = module.eks.cluster_endpoint,
    queue_name       = module.karpenter.queue_name,
    iam_role_arn     = module.karpenter.iam_role_arn,
    image_registry   = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  })]

  depends_on = [helm_release.karpenter_crd]
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
      - alias: bottlerocket@v1.46.0
      kubelet:
        maxPods: 100
      blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          deleteOnTermination: true
          %{if var.environment == "prod"}
          volumeSize: 30Gi
          %{else}
          volumeSize: 20Gi
          %{endif}
          volumeType: gp3
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2
        httpTokens: optional
      tags:
        Name: default
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = templatefile("./nodepools/default.yaml", {
    environment     = var.environment
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_on_demand" {
  yaml_body = templatefile("./nodepools/on-demand.yaml", {
    environment     = var.environment
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "on_demand_arm" {
  yaml_body = templatefile("./nodepools/on-demand-arm.yaml", {
    environment     = var.environment
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "spot_node_pool" {
  yaml_body = templatefile("./nodepools/spot.yaml", {
    environment     = var.environment
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "kubectl_manifest" "arm_spot_ci_node_pool" {
  yaml_body = templatefile("./nodepools/spot-arm.yaml", {
    environment     = var.environment
  })

  depends_on = [
    kubectl_manifest.node_class
  ]
}

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
  description      = "Service linked role for EC2 spot instances"
  lifecycle {
    prevent_destroy = false
  }
}