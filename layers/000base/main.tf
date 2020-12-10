###############################################################################
#########################   000base Layer  #########################
###############################################################################

###############################################################################
# Providers
###############################################################################
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

locals {
  tags = {
    Environment     = var.environment
    ServiceProvider = "Rackspace"
  }
}

###############################################################################
# Terraform main config
# terraform block cannot be interpolated; sample provided as output of _main
# `terraform output remote_state_configuration_example`
###############################################################################
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = "~> 3.6.0"
  }
  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-antonio-appmod-eks-helm"
    # This key must be unique for each layer!
    key     = "terraform.development.000base.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

###############################################################################
# Terraform Remote State
###############################################################################
data "terraform_remote_state" "main_state" {
  backend = "local"

  config = {
    path = "../../_main/terraform.tfstate"
  }
}

###############################################################################
# Base Network
# https://github.com/rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork
###############################################################################
module "base_network" {
  source               = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.12.2"
  name                 = var.vpc_name
  cidr_range           = var.cidr_range
  custom_azs           = var.custom_azs
  public_cidr_ranges   = var.public_cidr_ranges
  private_cidr_ranges  = var.private_cidr_ranges
  build_nat_gateways   = var.build_nat_gateways
  environment          = var.environment
  az_count             = var.az_count
}
