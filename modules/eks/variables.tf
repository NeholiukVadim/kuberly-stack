variable "environment" {
  type        = string
  description = "dev|staging|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region where to deploy the infrastructure"
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
variable "eks_access_aws_iam_users" {
  type        = map(any)
  description = "AWS IAM users with access to AWS EKS cluster"
}

variable "terraform_plan_role_name" {
  type        = string
  description = "CI/CD IAM role to run terraform plan"
}

variable "terraform_apply_role_name" {
  type        = string
  description = "CI/CD IAM role to run terraform apply"
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
