remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states"
        region         = "eu-central-1"
        key            = "ecr/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

inputs = {
    ecr_private_repos = ["tech-images", "admin", "client-docs"]
}

terraform {
    source = "../../../modules/ecr"
}

include "environment" {
    path = find_in_parent_folders("environment.hcl")
}