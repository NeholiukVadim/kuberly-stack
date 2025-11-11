remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${include.root.inputs.target.cluster.region}-${include.root.inputs.target.cluster.environment}-tf-states"
        region         = include.root.inputs.target.cluster.region
        key            = "eks/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "vpc" {
    config_path = "../vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
    kuberly_manager_role  = include.root.inputs.target.cluster.role_arn
    environment          = include.root.inputs.target.cluster.environment
    region              = include.root.inputs.target.cluster.region
    vpc_id              = dependency.vpc.outputs.vpc_id
    private_subnets_ids = dependency.vpc.outputs.private_subnets_ids
    account_id          = get_aws_account_id()
    cluster_endpoint_public  = true
    cluster_version          = include.root.inputs.target.cluster.version
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
