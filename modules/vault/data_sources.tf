# Data source to get the Vault service account
data "kubernetes_service_account" "vault" {
  depends_on = [helm_release.vault]
  metadata {
    name      = "vault"
    namespace = "vault"
  }
}

# Create a service account token for Vault
resource "kubernetes_secret" "vault_token" {
  depends_on = [helm_release.vault]
  metadata {
    name      = "vault-token"
    namespace = "vault"
    annotations = {
      "kubernetes.io/service-account.name" = "vault"
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Data source to get Vault root token
data "kubernetes_secret" "vault_unseal_keys" {
  depends_on = [helm_release.vault]
  metadata {
    name      = "vault-unseal-keys"
    namespace = "vault"
  }
}
