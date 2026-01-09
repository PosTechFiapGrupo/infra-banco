terraform {
  backend "s3" {
    # Configure these values for your environment
    # Note: The CI/CD workflow uses environment-specific state keys:
    # - dev: infra-db/dev/terraform.tfstate
    # - staging: infra-db/staging/terraform.tfstate
    # - prod: infra-db/prod/terraform.tfstate
    # These are passed via -backend-config flags in the workflow
    bucket         = "your-terraform-state-bucket"
    key            = "infra-db/terraform.tfstate"  # Default key, overridden in CI/CD
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

