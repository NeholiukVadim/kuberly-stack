locals {
    kuberly_config = jsondecode(file(find_in_parent_folders("kuberly.json")))
    region = local.kuberly_config.region
    environment = local.kuberly_config.environment
}

remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${local.region}-${local.environment}-tf-states"
        region         = local.region
        key            = "vpc/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

terraform {
    source = "."
}

inputs = {
    region = local.region
    environment = local.environment
    cidr_block = "10.0.0.0/16"
    private_subnets_cidrs = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
    public_subnets_cidrs  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}
