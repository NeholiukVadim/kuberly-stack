variable "environment" {
  type        = string
  description = "dev|staging|prod"
}

variable "region" {
  type        = string
  description = "Region where to deploy the infrastructure"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC where to deploy the infrastructure"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "AWS private subnets where to deploy the infrastructure"
}

variable "cluster_endpoint_public" {
  type        = bool
  description = "Whether the cluster endpoint is accessible publicly"
}
variable "cluster_version" {
  type        = string
  description = "Version of EKS cluster"
}
variable "eks_access_iam_users" {
  type        = list(string)
  description = "List of IAM role ARNs that should have admin access to the EKS cluster"
  default     = []
}

variable "kuberly_manager_role" {
  type        = string
  description = "Kuberly manager IAM role"
}

variable "vpn_instance_sg" {
  type        = string
  description = "AWS EC2 VPN instance id"
  default     = ""
}

variable "dlm_role_arn" {
  type        = string
  description = "Data Lifecycle Manager universal Role ARN"
  default     = ""
}

variable "bottlerocket_version" {
  type        = string
  description = "Bottlerocket version"
  default     = "1.50.0"
}