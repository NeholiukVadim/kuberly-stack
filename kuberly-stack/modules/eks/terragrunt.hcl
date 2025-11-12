include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  cluster_config = [
    for config in values(include.root.inputs) :
    config
    if try(config.target.cluster, null) != null
  ][0]
}

remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${local.cluster_config.target.cluster.region}-${local.cluster_config.target.cluster.environment}-tf-states"
        region         = local.cluster_config.target.cluster.region
        key            = "eks/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "vpc" {
    config_path = "../vpc"
}

inputs = {
    kuberly_manager_role  = local.cluster_config.target.cluster.role_arn
    environment          = local.cluster_config.target.cluster.environment
    region              = local.cluster_config.target.cluster.region
    vpc_id              = dependency.vpc.outputs.vpc_id
    private_subnets_ids = dependency.vpc.outputs.private_subnets_ids
    account_id          = get_aws_account_id()
    cluster_endpoint_public  = true
    cluster_version          = local.cluster_config.target.cluster.version
    eks_access_iam_users = try(local.cluster_config.target.cluster.eks_access_iam_users, [])
}

terraform {
    source = "."
}
