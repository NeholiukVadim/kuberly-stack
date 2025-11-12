resource "null_resource" "olm_release" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/values/olm-release.yaml"
  }
}