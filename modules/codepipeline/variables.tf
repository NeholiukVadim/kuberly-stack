variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "codebuild_names" {
  type        = list(string)
  description = "Codebuild names list"
}

variable "vpc_id" {
  type        = string
  description = "VPC id to deploy EKS cluster"
}

variable "private_subnets" {
  type        = list(string)
  description = "VPC subnets to deploy EKS cluster"
}

variable "eks_primary_sg" {
  type        = string
  description = "EKS primary security group id"
}

variable "codepipeline_secret_name" {
  type        = string
  description = "Codepipeline secret name (bitbucket)"
}

variable "allowed_assume_role_users" {
  type        = list(string)
  description = "List of IAM user ARNs allowed to assume the CodeBuild role"
  default     = []
}

variable "allowed_assume_role_arn" {
  type        = string
  description = "ARN of the assumed role allowed to assume the CodeBuild role"
  default     = ""
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}