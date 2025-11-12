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
  description = "AWS Account ID"
}

variable "aws_zone" {
  type        = string
  description = "AWS Zone"
}

variable "main_az_number" {
  type = number
  description = "1|2|3"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "vpc_private_subnet_ids" {
  type        = list(string)
  description = "VPC private subnets"
}

variable "vpc_public_subnet_ids" {
  type        = list(string)
  description = "VPC public subnets"
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
  default     = ""
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
  default     = ""
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "EKS cluster certificate authority data"
  default     = ""
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "EKS cluster OIDC issuer URL"
  default     = ""
}

variable "oidc_provider_arn" {
  type        = string
  description = "EKS cluster OIDC provider ARN data"
  default     = ""
}

variable "pritunl_secret_arn" {
  type        = string
  description = "ARN of the Pritunl Secrets Manager secret"
  default     = ""
}