remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
        key            = "kuberly/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "eks" {
    config_path = "../eks"
}

dependency "tools" {
    config_path = "../tools"
}

inputs = {
    cluster_name                       = dependency.eks.outputs.cluster_name
    cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
    cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
    cluster_oidc_provider_arn          = dependency.eks.outputs.cluster_oidc_provider_arn
    cluster_oidc_provider_id           = dependency.eks.outputs.cluster_oidc_provider_id
    k8s_operators_sa_role_arn          = dependency.tools.outputs.ack_controller_role_arn
    eks_delete_system_sa_role_arn      = dependency.eks.outputs.kuberly_internal_role_arn
}

terraform {
    source = "../../../modules/kuberly"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}
