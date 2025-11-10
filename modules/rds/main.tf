provider "aws" {
  region = var.aws_region
}

provider "aws" {
  region = var.aws_replication_region
  alias  = "replication"
}