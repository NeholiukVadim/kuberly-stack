variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name to deploy logging resources"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint to deploy logging resources"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "EKS cluster certificate authority data to deploy logging resources"
}

variable "aws_replication_region" {
  type        = string
  description = "AWS region where to replicate data"
  default     = ""
}

variable "db_security_group" {
  type        = string
  description = "DB SecurityGroup id"
}

variable "vpc_private_subnet_ids" {
  type        = list(string)
  description = "VPC private subnets"
}

variable "rds_instance_type" {
  type        = string
  description = "AWS RDS instance type"
}

variable "rds_multi_az" {
  type        = bool
  description = "AWS RDS instance mode"
}

variable "rds_version" {
  type        = string
  description = "AWS RDS postgres version"
}

locals {
  availability_zone = "${var.aws_region}a"
}