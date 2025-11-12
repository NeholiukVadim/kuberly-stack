module "nlb" {
  count  = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  source = "terraform-aws-modules/alb/aws"
  version = "9.7.0"

  load_balancer_type               = "network"
  name                             = "${var.environment}-vpn"
  vpc_id                           = var.vpc_id
  subnets                          = [var.vpc_public_subnet_ids[var.main_az_number]]
  enable_cross_zone_load_balancing = false
  create_security_group            = false
  enable_deletion_protection       = true

  listeners = {
    openvpn = {
      port = 1194
      protocol = "UDP"

      forward = {
        target_group_key = "openvpn"
      }
    }
    openvpnwp = {
      port = 1195
      protocol = "UDP"

      forward = {
        target_group_key = "openvpnwp"
      }
    }
    ssh = {
      port = 22
      protocol = "TCP"

      forward = {
        target_group_key = "ssh"
      }
    }
    https = {
      port = 443
      protocol = "TCP"

      forward = {
        target_group_key = "https"
      }
    }
  }

  target_groups = {
    openvpn = {
      name        = "openvpn"
      protocol    = "UDP"
      port        = 1194
      target_type = "instance"
      target_id   = aws_instance.this[0].id
      health_check = {
        port     = 443
        protocol = "TCP"
      }
    }
    openvpnwp = {
      name        = "openvpnwp"
      protocol    = "UDP"
      port        = 1195
      target_type = "instance"
      target_id   = aws_instance.this[0].id
      health_check = {
        port     = 443
        protocol = "TCP"
      }
    }
    ssh = {
      name        = "ssh"
      protocol    = "TCP"
      port        = 22
      target_type = "instance"
      target_id   = aws_instance.this[0].id
    }
    https = {
      name        = "https"
      protocol    = "TCP"
      port        = 443
      target_type = "instance"
      target_id   = aws_instance.this[0].id
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}