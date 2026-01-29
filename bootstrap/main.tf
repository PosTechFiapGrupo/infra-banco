locals {
  bucket_name = "s3-${var.project_name}-${var.environment}-tfstate"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
}
