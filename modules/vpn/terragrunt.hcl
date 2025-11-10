remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
        key            = "vpn/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "eks" {
    config_path = "../eks"
}

dependency "secrets" {
    config_path = "../secrets"
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

    vpc_id                             = dependency.vpc.outputs.vpc_id
    vpc_private_subnet_ids             = dependency.vpc.outputs.private_subnets_ids
    vpc_public_subnet_ids              = dependency.vpc.outputs.public_subnets_ids

    pritunl_secret_arn = dependency.secrets.outputs.pritunl_secret_arn
}

terraform {
    source = "../../../modules/vpn"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}