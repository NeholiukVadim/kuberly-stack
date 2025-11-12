resource "null_resource" "tekton_release" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/values/tekton-release-${var.environment}.yaml"
  }
}

resource "null_resource" "shipwright_release" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/values/shipwright-release-${var.environment}.yaml --server-side=true --force-conflicts"
  }

  depends_on = [null_resource.tekton_release]
}

# resource "null_resource" "shipwright_release" {
#   provisioner "local-exec" {
#     command = "kubectl apply -f ${path.module}/values/shipwright-release-${var.environment}.yaml --server-side=true"
#   }

#   # triggers = {
#   #   file_hash = filemd5("${path.module}/values/shipwright-release-${var.environment}.yaml")
#   # }

#   depends_on = [null_resource.tekton_release]
# }

# resource "kubectl_manifest" "shipwright_cert" {
#   for_each = toset(split("---", file("${path.module}/values/shipwright-cert.yaml")))

#   yaml_body = each.value

#   depends_on = [null_resource.shipwright_release, helm_release.cert-manager]
# }
