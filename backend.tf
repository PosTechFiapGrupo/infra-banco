terraform {
  backend "s3" {
    bucket       = "s3-tech-challenge-dev-tfstate"  # sem underscore
    key          = "infra/grupo19/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
