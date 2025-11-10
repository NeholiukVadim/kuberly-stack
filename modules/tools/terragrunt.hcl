locals {
    parent_config = read_terragrunt_config(find_in_parent_folders("root.hcl"))
    region = local.parent_config.locals.region
}

remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket         = "${get_aws_account_id()}-${include.root.inputs.region}-${include.root.inputs.environment}-tf-states"
        region         = "eu-west-1"
        key            = "tools/terraform.tfstate"
        use_lockfile   = true

        skip_bucket_enforced_tls = true
        skip_bucket_root_access  = true
    }
}

dependency "eks" {
    config_path = "../eks"
}

dependency "secrets" {
    config_path = "../secrets"
}

inputs = {
    prometheus_retention_period = "7d"
    prometheus_storage_size     = "60Gi"

    cluster_name                       = dependency.eks.outputs.cluster_name
    cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
    cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
    cluster_oidc_provider_arn          = dependency.eks.outputs.cluster_oidc_provider_arn
    cluster_oidc_provider_id           = dependency.eks.outputs.cluster_oidc_provider_id
    kuberly_internal_role_arn          = dependency.eks.outputs.kuberly_internal_role_arn
    csi_external_snapshotter_version   = "v6.1.0"

    discord_webhook_secret_id          = dependency.secrets.outputs.discord_webhook_secret_id

    csi_external_snapshotter_node_selector = {
        "kubernetes.io/arch"         = "arm64"
        "karpenter.sh/capacity-type" = "spot"
    }

    csi_external_snapshotter_tolerations = [
        {
            key      = "arch/arm"
            value    = "true"
            operator = "Equal"
            effect   = "NoSchedule"
        },
        {
            key      = "spot"
            value    = "true"
            operator = "Equal"
            effect   = "NoSchedule"
        }
    ]

    ack_controllers = {
        s3 = {
            version = "1.0.28"
            sets = {
                "aws.region" = local.region
            }
        },
        iam = {
            version = "1.3.19"
            sets = {
                "aws.region" = local.region
            }
        },
        eks = {
            version = "1.4.5"
            sets = {
                "aws.region" = local.region
            }
        },
        ec2 = {
            version = "1.2.24"
            sets = {
                "aws.region" = local.region
            }
        },
        elbv2 = {
            version = "1.0.1"
            sets = {
                "aws.region" = local.region
            }
        },
        ecr = {
            version = "1.0.26"
            sets = {
                "aws.region" = local.region
            }
        },
        eventbridge = {
            version = "1.0.21"
            sets = {
                "aws.region" = local.region
            }
        },
        sns = {
            version = "1.1.9"
            sets = {
                "aws.region" = local.region
            }
        },
        kafka = {
            version = "1.0.12"
            sets = {
                "aws.region" = local.region
            }
        },
        sqs = {
            version = "1.1.12"
            sets = {
                "aws.region" = local.region
            }
        },
        efs = {
            version = "1.0.16"
            sets = {
                "aws.region" = local.region
            }
        },
        rds = {
            version = "1.4.16"
            sets = {
                "aws.region" = local.region
            }
        },
        elasticache = {
            version = "0.2.3"
            sets = {
                "aws.region" = local.region
            }
        },
        documentdb = {
            version = "1.0.7"
            sets = {
                "aws.region" = local.region
            }
        },
        opensearchservice = {
            version = "1.0.9"
            sets = {
                "aws.region" = local.region
            }
        },
        kms = {
            version = "1.0.24"
            sets = {
                "aws.region" = local.region
            }
        }
        apigatewayv2 = {
            version = "1.1.1"
            sets = {
                "aws.region" = local.region
            }
        }
        lambda = {
            version = "1.9.1"
            sets = {
                "aws.region" = local.region
            }
        }
    }
}

terraform {
    source = "../../../modules/tools"
}

include "environment" {
    path = find_in_parent_folders("root.hcl")
}
