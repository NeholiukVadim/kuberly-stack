variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region where to deploy the infrastructure"
}

variable "cluster_endpoint" {
  type        = string
  description = "AWS EKS cluster endpoint"
  sensitive   = true
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "AWS EKS cluster certificate authority data"
  sensitive   = true
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "AWS EKS cluster OIDC provider ARN"
  sensitive   = true
}

variable "k8s_operators_sa_role_arn" {
  type        = string
  description = "K8s operators SA role"
}

variable "eks_delete_system_sa_role_arn" {
  type        = string
  description = "EKS delete SA role"
}