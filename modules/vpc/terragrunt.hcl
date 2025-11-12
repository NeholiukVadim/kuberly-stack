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
    environment             = local.cluster_config.target.cluster.environment
    region                  = local.cluster_config.target.cluster.region
    cidr_block              = local.cluster_config.target.vpc.cidr_block
    private_subnets_cidrs   = [for subnet in local.cluster_config.target.vpc.private_subnets : subnet.cidr_block]
    public_subnets_cidrs    = [for subnet in local.cluster_config.target.vpc.public_subnets : subnet.cidr_block]
}
