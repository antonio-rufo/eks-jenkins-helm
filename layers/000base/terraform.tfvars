###############################################################################
# Environment
###############################################################################
aws_account_id = "162198556136"
region         = "ap-southeast-2"
environment    = "Development"

###############################################################################
# Base Network
###############################################################################
vpc_name               = "main"
cidr_range             = "10.0.0.0/16"
custom_azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
public_cidr_ranges     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets_per_az  = 1
private_cidr_ranges    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
private_subnets_per_az = 1
build_nat_gateways     = "true"
az_count               = 3
