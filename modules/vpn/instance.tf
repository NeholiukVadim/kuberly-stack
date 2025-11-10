resource "aws_instance" "this" {
  count                  = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  ami                    = data.aws_ami.ubuntu[0].id
  instance_type          = "t3.micro"
  key_name               = "vpn-key"
  subnet_id              = var.vpc_private_subnet_ids[var.main_az_number]
  vpc_security_group_ids = [module.security_group[0].security_group_id]
  user_data_base64       = filebase64("./scripts/user_data.bash")
  root_block_device {
    delete_on_termination = false
  }

  tags = {
    Name = "vpn"
    backup = "true"
  }

  lifecycle {
    # In case VPN was restored using AMI/EBS snapshot
    ignore_changes = [ami]
  }
}

data "aws_ami" "ubuntu" {
  count       = var.environment == "prod" || var.environment == "dev" ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}