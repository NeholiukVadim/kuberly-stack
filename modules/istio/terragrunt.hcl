remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
        key            = "istio/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "eks" {
    config_path = "../eks"
}

dependency "vpc" {
    config_path = "../vpc"
}

inputs = {
    cluster_name                       = dependency.eks.outputs.cluster_name
    cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
    cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
    cluster_oidc_provider_arn          = dependency.eks.outputs.cluster_oidc_provider_arn
    oidc_provider_arn                  = dependency.eks.outputs.cluster_oidc_provider_arn
    cluster_oidc_issuer_url            = dependency.eks.outputs.cluster_oidc_issuer_url
    nat_ips                            = dependency.vpc.outputs.nat_ips
}

terraform {
    source = "../../../modules/istio"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}