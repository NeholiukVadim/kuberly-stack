variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "dns_domain" {
  type        = string
  description = "Site name without subdomains for environment resources"
}

variable "cert_manager_route53_role" {
  type        = string
  sensitive   = true
  description = "AWS IAM role for cert manager SA"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "EKS cluster certificate authority data"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "EKS cluster OIDC issuer URL"
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "AWS EKS cluster OIDC provider ARN"
  sensitive   = true
}
