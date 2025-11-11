remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${include.root.inputs.target.cluster.region}-${include.root.inputs.target.cluster.environment}-tf-states"
        region         = include.root.inputs.target.cluster.region
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
    environment             = include.root.inputs.target.cluster.environment
    region                  = include.root.inputs.target.cluster.region
    cidr_block              = include.root.inputs.target.vpc.cidr_block
    private_subnets_cidrs   = [for subnet in include.root.inputs.target.vpc.private_subnets : subnet.cidr_block]
    public_subnets_cidrs    = [for subnet in include.root.inputs.target.vpc.public_subnets : subnet.cidr_block]
}
