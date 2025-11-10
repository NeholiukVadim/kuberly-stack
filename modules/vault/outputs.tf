output "vault_kms_key_id" {
  description = "Vault KMS key ID for unsealing"
  value       = aws_kms_key.vault.id
}

output "vault_kms_key_arn" {
  description = "Vault KMS key ARN for unsealing"
  value       = aws_kms_key.vault.arn
}

output "vault_irsa_role_arn" {
  description = "Vault IRSA role ARN"
  value       = module.vault_irsa_role.iam_role_arn
}

output "vault_pki_client_csr" {
  description = "PKI client intermediate CA CSR"
  value       = vault_pki_secret_backend_intermediate_cert_request.pki_client.csr
  sensitive   = true
}

output "vault_kubernetes_auth_path" {
  description = "Kubernetes authentication path"
  value       = vault_auth_backend.kubernetes.path
}

output "vault_pki_client_path" {
  description = "PKI client secrets engine path"
  value       = vault_mount.pki_client.path
}

output "vault_pki_role_name" {
  description = "PKI role name for cert-manager"
  value       = vault_pki_secret_backend_role.cert_manager.name
}

output "vault_pki_kuberly_client_role_name" {
  description = "PKI role name for kuberly-client"
  value       = vault_pki_secret_backend_role.kuberly_client.name
}

output "cert_manager_issuer_name" {
  description = "Name of the cert-manager ClusterIssuer"
  value       = "kuberly-client-issuer"
}
