module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = var.environment
  cidr = var.cidr_block

  azs             = data.aws_availability_zones.active.names
  private_subnets = var.private_subnets_cidrs
  public_subnets  = var.public_subnets_cidrs

  single_nat_gateway = true
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.environment
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  map_public_ip_on_launch = true
  enable_nat_gateway      = true

  default_network_acl_ingress = [{
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    }, {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 22
    to_port    = 22
    }, {
    protocol   = "tcp"
    rule_no    = 20
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
    }, {
    protocol   = "tcp"
    rule_no    = 30
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }]

  default_network_acl_egress = [{
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }]
}