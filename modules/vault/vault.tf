resource "helm_release" "vault" {
  namespace        = "vault"
  create_namespace = true

  name       = "vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  version    = "0.31.0"

  values = [templatefile("./values/vault.yaml", {
    aws_region = var.aws_region,
    kms_key    = aws_kms_key.vault.id,
    role_arn   = module.vault_irsa_role.iam_role_arn
  })]

  # Port forward to Vault service for configuration
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "nohup kubectl port-forward svc/vault 8200:8200 --namespace vault >/dev/null 2>&1 & echo $! > /tmp/vault-port-forward.pid"
  }

  # Clean up port forward on destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "pkill -f 'kubectl port-forward svc/vault 8200:8200 --namespace vault' || true; rm -f /tmp/vault-port-forward.pid"
  }
}
