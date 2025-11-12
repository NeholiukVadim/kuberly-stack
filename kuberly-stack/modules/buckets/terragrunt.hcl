remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states"
        region         = "eu-central-1"
        key            = "buckets/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

terraform {
    source = "../../../modules/buckets"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}

inputs = {
    terraform_plan_role_name  = "codebuild-plan-eu-west-1"
    terraform_apply_role_name = "codebuild-apply-eu-west-1"

    aws_iam_users                = ["vadimn@profisea.com"]
    backups_access_aws_iam_users = ["vadimn@profisea.com"]

    aws_replication_region       = "eu-central-1"
}
