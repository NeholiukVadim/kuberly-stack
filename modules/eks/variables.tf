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
variable "addon_vpc_cni_version" {
  type        = string
  description = "Version of vpc_cni addon"
}
variable "addon_coredns_version" {
  type        = string
  description = "Version of coredns addon"
}
variable "addon_kube_proxy_version" {
  type        = string
  description = "Version of kube_proxy addon"
}
variable "addon_ebs_csi_version" {
  type        = string
  description = "Version of ebs_csi addon"
}
variable "addon_pod_identity_version" {
  type        = string
  description = "Version of ebs_csi addon"
}
variable "eks_access_iam_users" {
  type        = list(string)
  description = "List of IAM user names (SSO usernames) that should have admin access to the EKS cluster"
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