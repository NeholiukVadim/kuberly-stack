variable "environment" {
  type        = string
  description = "dev|staging|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region where to deploy the infrastructure"
}

variable "aws_replication_region" {
  type        = string
  description = "AWS region where to replicate data"
}

variable "terraform_plan_role_name" {
  type        = string
  description = "AWS IAM role used to run Infra pipeline plan"
}

variable "terraform_apply_role_name" {
  type        = string
  description = "AWS IAM role used to run Infra pipeline apply"
}

variable "aws_iam_users" {
  type        = list(any)
  description = "AWS IAM users to use in configuration"
}

variable "devops_admin_policy_arns" {
  type = map(string)
  default = {
    "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess",
  }
}

variable "backups_access_aws_iam_users" {
  type        = list(any)
  description = "AWS IAM users with access to backups S3 buckets"
}