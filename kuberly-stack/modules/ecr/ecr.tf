module "ecr_private" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "2.4.0"

  for_each        = var.environment == "prod" ? toset(var.ecr_private_repos) : toset([])
  repository_name = each.key

  repository_read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  create_lifecycle_policy           = false

  repository_force_delete         = false
  repository_image_scan_on_push   = false
  repository_image_tag_mutability = "MUTABLE"
}
