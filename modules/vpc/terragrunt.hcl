remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${include.root.inputs.eks.region}-${include.root.inputs.eks.environment}-tf-states"
        region         = include.root.inputs.eks.region
        key            = "vpc/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

terraform {
    source = "."
}

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
    environment          = include.root.inputs.eks.environment
    region              = include.root.inputs.eks.region
    cidr_block = "10.0.0.0/16"
    private_subnets_cidrs = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
    public_subnets_cidrs  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}
