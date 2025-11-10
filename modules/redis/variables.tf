variable "environment" {
  type        = string
  description = "dev|stage|prod"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_private_subnet_ids" {
  type        = list(string)
  description = "VPC private subnets"
}

variable "db_security_group" {
  type        = string
  description = "DB SecurityGroup id"
}

variable "redis_multi_az" {
  type        = bool
  description = "Whether to enable AWS ElastiCache Redis MultiAZ"
}

variable "redis_replicated" {
  type        = bool
  description = "Whether to enable AWS ElastiCache Redis replicas"
}

variable "redis_instance_type" {
  type        = string
  description = "AWS ElastiCache Redis instance type"
}

variable "redis_version" {
  type        = string
  description = "ElastiCache Redis engine version"
}