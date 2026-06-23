provider "aws" {
  region = "us-east-1"
}

# 1. Base Networking
module "network" {
  source          = "../../modules/network"
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
}

# 2. Base Firewall Boundaries
module "security" {
  source = "../../modules/security"
  vpc_id = module.network.vpc_id
}

# 3. The Compute Platform Engine
module "eks" {
  source       = "../../modules/eks"
  cluster_name = "dev-eks"
  role_arn     = "arn:aws:iam::763054201983:role/eks-cluster-admin-role"
  subnet_ids   = module.network.private_subnet_ids
}

# 4. The Platform Image Registry
module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "backend-api"
}