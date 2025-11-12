output "cluster_endpoint" {
  value     = var.cluster_endpoint
  sensitive = true
}

output "cluster_certificate_authority_data" {
  value     = var.cluster_certificate_authority_data
  sensitive = true
}

output "cluster_oidc_provider_arn" {
  value     = var.cluster_oidc_provider_arn
  sensitive = true
}

output "cluster_oidc_provider_id" {
  value     = var.cluster_oidc_provider
  sensitive = true
}

output "cluster_oidc_issuer_url" {
  value     = var.cluster_oidc_issuer_url
  sensitive = true
}

output "cluster_name" {
  value     = var.cluster_name
  sensitive = true
}

output "cluster_primary_security_group_id" {
  value = var.cluster_primary_security_group_id
}

output "k8s_manager_sa_role_arn" {
  value = var.k8s_manager_sa_role_arn
}

output "internal_role_arn" {
  value = var.internal_role_arn
}