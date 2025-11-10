remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-eu-terraform-states-dev"
        region         = "eu-west-1"
        key            = "codepipeline/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "vpc" {
    config_path = "../vpc"
}

dependency "eks" {
    config_path = "../eks"
}

dependency "secrets" {
    config_path = "../secrets"
}

dependency "ecr" {
    config_path = "../ecr"
    skip_outputs = true
}

inputs = {
    codebuild_names = ["plan", "apply"]

    vpc_id          = dependency.vpc.outputs.vpc_id
    private_subnets = dependency.vpc.outputs.private_subnets_ids

    eks_primary_sg  = dependency.eks.outputs.cluster_primary_security_group_id

    codepipeline_secret_name = dependency.secrets.outputs.codepipeline_secret_name

    allowed_assume_role_users = [
        "arn:aws:sts::${get_aws_account_id()}:assumed-role/codebuild-plan-eu-west-1/plan",
        "arn:aws:iam::${get_aws_account_id()}:user/vadimn@profisea.com",
        "arn:aws:sts::${get_aws_account_id()}:assumed-role/AWSReservedSSO_AdministratorAccess_2379587cbeadc092/antongri@profisealabs.com",
        "arn:aws:sts::${get_aws_account_id()}:assumed-role/AWSReservedSSO_AdministratorAccess_2379587cbeadc092/nikitac@profisealabs.com",
        "arn:aws:sts::${get_aws_account_id()}:assumed-role/AWSReservedSSO_AdministratorAccess_2379587cbeadc092/Hermanl@profisealabs.com"
    ]
    aws_account_id = get_aws_account_id()
}

terraform {
    source = "../../../modules/codepipeline"
}

include "environment" {
    path = find_in_parent_folders("environment.hcl")
}
