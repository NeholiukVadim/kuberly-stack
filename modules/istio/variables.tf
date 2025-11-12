variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
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

variable "oidc_provider_arn" {
  type        = string
  description = "EKS cluster OIDC provider ARN data"
}

variable "nat_ips" {
  type        = list(string)
  description = "NAT IP addresses"
}

locals {
  nat_ip = var.nat_ips[0]
}