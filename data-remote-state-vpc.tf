# =============================================================================
# Remote State - VPC
# =============================================================================

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = var.vpc_remote_state_region
  }
}

# =============================================================================
# Locals - VPC (remote state OU override manual)
# =============================================================================

locals {
  # VPC ID
  vpc_id = (
    var.use_remote_state
    ? try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
    : var.vpc_id_override
  )

  # VPC CIDR
  vpc_cidr = (
    var.use_remote_state
    ? try(data.terraform_remote_state.vpc.outputs.vpc_cidr, null)
    : var.vpc_cidr_override
  )

  # Subnets privadas
  private_subnet_ids = (
    var.use_remote_state
    ? try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
    : var.private_subnet_ids_override
  )

  # Subnets públicas (caso use)
  public_subnet_ids = (
    var.use_remote_state
    ? try(data.terraform_remote_state.vpc.outputs.public_subnet_ids, [])
    : var.public_subnet_ids_override
  )
}
