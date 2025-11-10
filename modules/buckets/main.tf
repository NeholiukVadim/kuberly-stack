provider "aws" {
  region = var.aws_region
}

provider "aws" {
  region = var.aws_replication_region
  alias  = "replication"
}

data "aws_caller_identity" "current" {}