resource "aws_security_group" "db_sg" {
  count = var.environment == "prod" ? 1 : 0

  name        = "${var.environment}-db"
  description = "Allow access to databases and caches"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Allows ingress traffic to dbs and caches from itself"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      from_port        = 0
      to_port          = 0
      protocol         = -1
      self             = true
    },
    {
      description      = "Allows ingress traffic to dbs and caches from EKS cluster"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [module.eks.node_security_group_id]
      from_port        = 0
      to_port          = 0
      protocol         = -1
      self             = false
    },
    {
      description      = "Allows ingress traffic to dbs and caches from VPN"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.vpn_instance_sg]
      from_port        = 0
      to_port          = 0
      protocol         = -1
      self             = false
    }
  ]

  tags = {
    Name = "${var.environment}-db"
  }
}