variable "environment" {
  type        = string
  description = "dev|staging|prod"
}

variable "region" {
  type        = string
  description = "Region where to deploy the infrastructure"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
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
variable "addon_efs_csi_version" {
  type        = string
  description = "Version of efs_csi addon"
}
variable "addon_pod_identity_version" {
  type        = string
  description = "Version of ebs_csi addon"
}

variable "bottlerocket_version" {
  type        = string
  description = "Bottlerocket version"
  default     = "1.50.0"
}

# Cluster information from eks module
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
  sensitive   = true
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "EKS cluster certificate authority data"
  sensitive   = true
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "EKS cluster OIDC provider ARN"
}

variable "cluster_oidc_provider" {
  type        = string
  description = "EKS cluster OIDC provider ID"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "EKS cluster OIDC issuer URL"
}

variable "cluster_primary_security_group_id" {
  type        = string
  description = "EKS cluster primary security group ID"
}

# IRSA role ARNs from eks module
variable "k8s_manager_sa_role_arn" {
  type        = string
  description = "K8s manager service account IAM role ARN"
  default     = ""
}

variable "internal_role_arn" {
  type        = string
  description = "Internal IAM role ARN"
  default     = ""
}

variable "on_demand_zones" {
  type        = list(string)
  description = "List of availability zones for on-demand NodePool zone requirements"
  default     = []
}

variable "spot_zones" {
  type        = list(string)
  description = "List of availability zones for spot NodePool zone requirements (typically all zones)"
  default     = []
}

variable "capacity_type_mode" {
  type        = string
  description = "Capacity type mode (spot or on-demand) for addon node selectors"
  default     = ""
}

variable "karpenter_version" {
  type        = string
  description = "Karpenter version"
  default     = ""
}