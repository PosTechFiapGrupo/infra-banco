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
# Remote State - K8S / EKS
# =============================================================================

data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket = var.k8s_remote_state_bucket
    key    = var.k8s_remote_state_key
    region = var.k8s_remote_state_region
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

  # -------------------------
  # EKS - SG dos Nodes
  # (prefere eks_nodes_sg_id; fallback p/ eks_nodes_security_group_id)
  # -------------------------
  eks_nodes_sg_id = (
    var.use_remote_state
    ? try(
        data.terraform_remote_state.k8s.outputs.eks_nodes_sg_id,
        data.terraform_remote_state.k8s.outputs.eks_nodes_security_group_id,
        null
      )
    : var.eks_nodes_sg_id_override
  )

  # -------------------------
  # EKS - Cluster Security Group
  # Preferir string: eks_cluster_security_group_id (seu infra-k8s exporta)
  # Fallbacks: cluster_security_group_id (pode ser lista/tuple)
  # -------------------------
  eks_cluster_sg_id = (
    var.use_remote_state
    ? try(
        data.terraform_remote_state.k8s.outputs.eks_cluster_security_group_id,
        one(data.terraform_remote_state.k8s.outputs.cluster_security_group_id),
        data.terraform_remote_state.k8s.outputs.cluster_security_group_id[0],
        null
      )
    : var.eks_cluster_sg_id_override
  )

  # -------------------------
  # SGs permitidos no RDS
  # -------------------------
  effective_allowed_security_group_ids = distinct(compact(concat(
    var.allowed_security_group_ids,
    [local.eks_nodes_sg_id],
    [local.eks_cluster_sg_id]
  )))
}
