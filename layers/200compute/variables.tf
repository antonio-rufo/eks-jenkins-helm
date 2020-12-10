###############################################################################
# Variables - Environment
###############################################################################
variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "region" {
  description = "Default Region"
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Name of the environment for the deployment, e.g. Integration, PreProduction, Production, QA, Staging, Test"
  default     = "Development"
}

variable "INSTANCE_DEVICE_NAME" {
  default = "/dev/xvdh"
}

variable "JENKINS_VERSION" {
  default = "2.204.5"
}

variable "TERRAFORM_VERSION" {
  default = "0.12.29"
}

variable "internal_key_pair" {
  description = "key pair for internal ec2 resources"
}
