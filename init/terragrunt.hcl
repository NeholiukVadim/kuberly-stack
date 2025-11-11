terraform {
    source = "."
}

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

inputs = {
    region = local.cluster_config.target.cluster.region
    environment = local.cluster_config.target.cluster.environment
}