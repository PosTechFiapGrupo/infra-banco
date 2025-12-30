terraform {
  backend "s3" {
    # Configure these values for your environment
    bucket         = "your-terraform-state-bucket"
    key            = "infra-db/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

