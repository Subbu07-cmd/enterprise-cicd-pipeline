module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access           = var.public_endpoint
  enable_cluster_creator_admin_permissions = true
  cluster_enabled_log_types                = ["api", "audit", "authenticator"]

  eks_managed_node_groups = {
    default = {
      instance_types = var.instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.min_size
      capacity_type  = var.spot ? "SPOT" : "ON_DEMAND"
    }
  }
  tags = var.tags
}

variable "cluster_name" { type = string }
variable "cluster_version" {
  type    = string
  default = "1.30"
}
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}
variable "min_size" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 6
}
variable "spot" {
  type    = bool
  default = false
}
variable "public_endpoint" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "node_security_group_id" { value = module.eks.node_security_group_id }
