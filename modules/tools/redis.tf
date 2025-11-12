resource "helm_release" "redis" {
  count = var.environment != "prod" ? 1 : 0
  
  name             = "redis"
  namespace        = "kuberly"
  create_namespace = false
  repository       = "oci://${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  chart            = "redis"
  version          = "20.6.3"
  values           = [templatefile("./values/redis.yaml", {
    aws_zone       = var.aws_zone
    image_registry = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  })]
}