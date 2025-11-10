variable "private_subnets_cidrs" {
  description = "List of CIDRs for VPC private subnets"
  type        = list(string)
}

variable "public_subnets_cidrs" {
  description = "List of CIDRs for VPC public subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "AWS environment"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}