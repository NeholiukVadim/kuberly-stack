resource "null_resource" "alb_controller_release" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/values/alb-controller-release.yaml --server-side=true"
  }
}