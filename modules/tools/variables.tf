variable "environment" {
  type        = string
  description = "dev|staging|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region where to deploy the infrastructure"
}

variable "cluster_name" {
  type        = string
  description = "AWS EKS cluster name"
  sensitive   = true
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

variable "cluster_oidc_provider_id" {
  description = "AWS EKS cluster OIDC provider ID"
  type        = string
  sensitive   = true
}

variable "prometheus_retention_period" {
  type        = string
  description = "Prometheus metrics retention period"
  default     = ""
}

variable "prometheus_storage_size" {
  type        = string
  description = "Prometheus storage size"
  default     = ""
}

variable "csi_external_snapshotter_version" {
  type        = string
  description = "CSI external snapshotter version"
  default     = ""
}

variable "ack_controllers" {
  type = map(object({
    version   = string
    sets      = optional(map(string))
  }))
  description = "Configurations of ACK controllers"
}

variable "dns_domain" {
  description = "The domain name for the Grafana instance"
  type        = string
}

variable "aws_zone" {
  type        = string
  description = "AWS Zone"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "discord_webhook_secret_id" {
  type        = string
  description = "AWS discord webhook secret ID"
}

variable "kuberly_internal_role_arn" {
  type        = string
  description = "Kuberly internal role arn"
  default     = ""
}

variable "csi_external_snapshotter_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "Tolerations for CSI external snapshotter deployment"
  default = [
    {
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    },
    {
      effect   = "NoSchedule"
      key      = "node-role.kubernetes.io/control-plane"
    },
    {
      key      = "arch/arm"
      value    = "true"
      operator = "Equal"
      effect   = "NoSchedule"
    }
  ]
}

variable "csi_external_snapshotter_node_selector" {
  type        = map(string)
  description = "Node selector for CSI external snapshotter deployment"
  default = {
    "kubernetes.io/arch"         = "arm64"
    "karpenter.sh/capacity-type" = "on-demand"
  }
}

variable "csi_external_snapshotter_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for CSI external snapshotter deployment"
  default = {
    limits = {
      cpu    = "10m"
      memory = "24Mi"
    }
    requests = {
      cpu    = "10m"
      memory = "24Mi"
    }
  }
}
