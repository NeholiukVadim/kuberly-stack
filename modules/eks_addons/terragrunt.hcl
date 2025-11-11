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
  
  topology = try(local.cluster_config.target.cluster.capacity_type.topology, "single-zone")
  capacity_type_mode = try(local.cluster_config.target.cluster.capacity_type.mode, "spot")
  private_subnets = try(local.cluster_config.target.vpc.private_subnets, [])
  
  on_demand_zones = local.topology == "single-zone" ? (
    [local.private_subnets[1].availability_zone]
  ) : (
    [for subnet in local.private_subnets : subnet.availability_zone]
  )
  
  spot_zones = local.topology == "single-zone" ? (
    [local.private_subnets[1].availability_zone]
  ) : (
    [for subnet in local.private_subnets : subnet.availability_zone]
  )
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
        key            = "eks_addons/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "eks" {
    config_path = "../eks"
    skip_outputs = false
}

inputs = {
    environment          = local.cluster_config.target.cluster.environment
    region              = local.cluster_config.target.cluster.region
    account_id          = get_aws_account_id()
    addon_vpc_cni_version    = "v1.20.4-eksbuild.2"
    addon_coredns_version    = "v1.12.4-eksbuild.1"
    addon_kube_proxy_version = "v1.34.0-eksbuild.4"
    addon_ebs_csi_version    = "v1.52.1-eksbuild.1"
    addon_pod_identity_version = "v1.3.9-eksbuild.5"
    addon_efs_csi_version = "v2.1.13-eksbuild.1"
    cluster_name                        = dependency.eks.outputs.cluster_name
    cluster_endpoint                    = dependency.eks.outputs.cluster_endpoint
    cluster_certificate_authority_data  = dependency.eks.outputs.cluster_certificate_authority_data
    cluster_oidc_provider_arn           = dependency.eks.outputs.cluster_oidc_provider_arn
    cluster_oidc_provider               = dependency.eks.outputs.cluster_oidc_provider_id
    cluster_oidc_issuer_url             = dependency.eks.outputs.cluster_oidc_issuer_url
    cluster_primary_security_group_id    = dependency.eks.outputs.cluster_primary_security_group_id
    k8s_manager_sa_role_arn = dependency.eks.outputs.k8s_manager_sa_role_arn
    internal_role_arn       = dependency.eks.outputs.internal_role_arn
    on_demand_zones         = local.on_demand_zones
    spot_zones              = local.spot_zones
    capacity_type_mode      = local.capacity_type_mode
}

terraform {
    source = "."
}
