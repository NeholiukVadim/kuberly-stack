output "name" {
  value = module.vpc.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnets_ids" {
  value = module.vpc.private_subnets
}

output "public_subnets_ids" {
  value = module.vpc.public_subnets
}

output "private_route_tables_ids" {
  value = module.vpc.private_route_table_ids
}

output "nat_ips" {
  value = module.vpc.nat_public_ips
}