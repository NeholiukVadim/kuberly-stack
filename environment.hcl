locals {
    region = "eu-west-1"
    zone   = "eu-west-1a"
}

inputs = {
    aws_region     = local.region
    aws_zone       = local.zone
    environment    = "dev"
    dns_domain     = "dev.kuberly.io"
    account_id     = "${get_aws_account_id()}"
    main_az_number = 0
}