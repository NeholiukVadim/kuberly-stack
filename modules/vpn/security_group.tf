module "security_group" {
  count  = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  source = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name   = "${var.environment}-vpn"
  vpc_id = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "openvpn-udp"
      cidr_blocks = "0.0.0.0/0"
    }, {
      from_port   = 1195
      to_port     = 1195
      protocol    = "udp"
      description = "OpenVPN WP SFTP"
      cidr_blocks = "0.0.0.0/0"
    }, {
      rule        = "ssh-tcp"
      cidr_blocks = "10.0.0.0/16"
    }, {
      rule        = "https-443-tcp"
      cidr_blocks = "10.0.0.0/16"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}