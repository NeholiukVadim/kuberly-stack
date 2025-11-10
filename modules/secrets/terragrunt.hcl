remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
        key            = "secrets/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

inputs = {}
include "environment" {
    path = find_in_parent_folders("root.hcl")
}
terraform {
    source = "../../../modules/secrets"
}
