output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "cluster_oidc_provider_arn" {
  value     = module.eks.oidc_provider_arn
  sensitive = true
}

output "cluster_oidc_provider_id" {
  value     = module.eks.oidc_provider
  sensitive = true
}

output "cluster_oidc_issuer_url" {
  value     = module.eks.cluster_oidc_issuer_url
  sensitive = true
}

output "cluster_name" {
  value     = module.eks.cluster_name
  sensitive = true
}

output "cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}

output "k8s_manager_sa_role_arn" {
  value = module.k8s-manager.iam_role_arn
}

output "internal_role_arn" {
  value = module.internal_role.iam_role_arn
}