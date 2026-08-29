terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ========== VPC (Virtual Private Cloud) ==========
# Think of VPC as your own private network inside AWS
# Public subnets = accessible from internet (for load balancer)
# Private subnets = hidden from internet (for your app pods)

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # These tags tell EKS which subnets to use
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Project     = var.project
    Environment = "dev"
  }
}

# ========== EKS (Kubernetes Cluster) ==========
# This creates your Kubernetes cluster on AWS

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "${var.project}-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    workers = {
      instance_types = ["t3.micro"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  tags = {
    Project     = var.project
    Environment = "dev"
  }
}

# ========== ECR (Container Registry) ==========
# This is where your Docker images get stored on AWS
# Like Docker Hub, but private and inside your AWS account

resource "aws_ecr_repository" "order_service" {
  name                 = "order-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = var.project
  }
}

resource "aws_ecr_repository" "inventory_service" {
  name                 = "inventory-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = var.project
  }
}