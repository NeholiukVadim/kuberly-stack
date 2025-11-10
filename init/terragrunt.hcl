terraform {
    source = "."
}

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
    region = include.root.inputs.eks.region
    environment = include.root.inputs.eks.environment
}