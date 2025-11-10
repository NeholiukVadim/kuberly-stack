remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
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
    terraform_plan_role_name  = "codebuild-plan-eu-west-1"
    terraform_apply_role_name = "codebuild-apply-eu-west-1"

    vpc_id              = dependency.vpc.outputs.vpc_id
    private_subnets_ids = dependency.vpc.outputs.private_subnets_ids

    cluster_endpoint_public  = true
    cluster_version          = "1.33"
    addon_vpc_cni_version    = "v1.19.2-eksbuild.1"
    addon_coredns_version    = "v1.11.4-eksbuild.2"
    addon_kube_proxy_version = "v1.32.0-eksbuild.2"
    addon_ebs_csi_version    = "v1.38.1-eksbuild.2"
    addon_pod_identity_version = "v1.3.4-eksbuild.1"
    eks_access_aws_iam_users = {
        "admins" = ["AWSReservedSSO_AdministratorAccess_2379587cbeadc092"]
        "devs"   = []
    }
}

terraform {
    source = "../../../modules/eks"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}