terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket       = "epicbook-terraform-state-dev-unique-167533875160-us-east-1-an" # Replace with your actual bucket name
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Network Layer
module "network" {
  source                    = "../../modules/network"
  vpc_cidr                  = var.vpc_cidr
  environment               = var.environment
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  availability_zones        = var.availability_zones
}

# 2. Security Layer
module "security_groups" {
  source      = "../../modules/security_groups"
  vpc_id      = module.network.vpc_id
  environment = var.environment
  app_port    = var.app_port
}

# 3. Database Layer
module "rds" {
  source                  = "../../modules/rds"
  private_data_subnet_ids = module.network.private_data_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id
  environment             = var.environment
  db_password             = var.db_password
}

# 4. Compute Layer
module "compute" {
  source                 = "../../modules/compute"
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  alb_sg_id              = module.security_groups.alb_sg_id
  app_sg_id              = module.security_groups.app_sg_id
  environment            = var.environment
  app_port               = var.app_port
}