terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "cicd-platform/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = local.tags }
}

locals {
  name = "platform-staging"
  tags = { Environment = "staging", ManagedBy = "terraform", Project = "cicd-platform" }
}

module "network" {
  source             = "../../modules/network"
  name               = local.name
  cidr               = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "ecr" {
  source = "../../modules/ecr"
  name   = "sample-service-staging"
  tags   = local.tags
}

module "eks" {
  source         = "../../modules/eks"
  cluster_name   = local.name
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.private_subnet_ids
  instance_types = var.instance_types
  min_size       = var.min_nodes
  max_size       = var.max_nodes
  spot           = var.spot
  tags           = local.tags
}

module "rds" {
  source                     = "../../modules/rds"
  name                       = "${local.name}-db"
  db_name                    = "app"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]
  multi_az                   = var.multi_az
  tags                       = local.tags
}
