output "ack_controller_role_arn" {
  description = "ARN of the ACK controller IAM role"
  value       = aws_iam_role.ack_controller_role.arn
}