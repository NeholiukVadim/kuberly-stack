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
    addon_vpc_cni_version    = "v1.19.2-eksbuild.1"
    addon_coredns_version    = "v1.11.4-eksbuild.2"
    addon_kube_proxy_version = "v1.32.0-eksbuild.2"
    addon_ebs_csi_version    = "v1.38.1-eksbuild.2"
    addon_pod_identity_version = "v1.3.4-eksbuild.1"
    eks_access_iam_users = ["AWSReservedSSO_AdministratorAccess_2379587cbeadc092"]
}

terraform {
    source = "."
}
