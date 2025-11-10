output "vpn_instance_sg" {
  value = var.environment == "prod" ? module.security_group[0].security_group_id : ""
}

output "dlm_role_arn" {
  value = var.environment == "prod" ? aws_iam_role.dlm[0].arn : ""
}