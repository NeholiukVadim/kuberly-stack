variable "aws_region" {
  type        = string
  description = "AWS region where to deploy the infrastructure"
}

variable "ecr_private_repos" {
  type        = list(string)
  description = "AWS private ECRs names"
}

variable "environment" {
  type        = string
  description = "dev|staging|prod"
}