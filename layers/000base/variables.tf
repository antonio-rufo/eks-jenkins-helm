###############################################################################
# Variables - Environment
###############################################################################
variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "region" {
  description = "Default Region"
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Name of the environment for the deployment, e.g. Integration, PreProduction, Production, QA, Staging, Test"
  default     = "Development"
}

variable "env" {
  description = "Short environment variable, e.g. Dev, Prod, Test"
  default     = "Dev"
}

###############################################################################
# Variables - Base Network
###############################################################################

variable "vpc_name" {
  description = "Name for the VPC	"
  default     = "BaseNetwork"
}

variable "cidr_range" {
  description = "CIDR range for the VPC"
}

variable "custom_azs" {
  description = "A list of AZs that VPC resources will reside in"
  type        = list(string)
}

variable "private_cidr_ranges" {
  description = "An array of CIDR ranges to use for private subnets"
  type        = list(string)
}

variable "private_subnets_per_az" {
  description = "Number of private subnets to create in each AZ. NOTE: This value, when multiplied by the value of az_count, should not exceed the length of the private_cidr_ranges list!"
}

variable "public_cidr_ranges" {
  description = "An array of CIDR ranges to use for public subnets"
  type        = list(string)
}

variable "public_subnets_per_az" {
  description = "Number of public subnets to create in each AZ. NOTE: This value, when multiplied by the value of az_count, should not exceed the length of the public_cidr_ranges list!"
}

variable "build_nat_gateways" {
  description = "Whether or not to build a NAT gateway per AZ. if build_igw is set to false, this value is ignored."
}

variable "az_count" {
  description = "Number of AZs to utilize for the subnets"
}
