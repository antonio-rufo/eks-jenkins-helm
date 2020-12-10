
###############################################################################
######################### 200compute Layer  #########################
###############################################################################

###############################################################################
# Providers
###############################################################################
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
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
  required_version = "> 0.12, < 0.13"
  required_providers {
    aws = "~> 3.6.0"
  }

  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-appmod"
    # This key must be unique for each layer!
    key     = "terraform.production.200compute.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

###############################################################################
# Terraform Remote State
###############################################################################
# _main
data "terraform_remote_state" "main_state" {
  backend = "local"

  config = {
    path = "../../_main/terraform.tfstate"
  }
}

# Remote State Locals
locals {
  state_bucket_id = data.terraform_remote_state.main_state.outputs.state_bucket_id
}

# 000base
# Get sample config from 000base layer `terraform output state_import_example`
# A name must start with a letter and may contain only letters, digits, underscores, and dashes.
data "terraform_remote_state" "base_network" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-appmod"
    key     = "terraform.production.000base.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# Remote State Locals
locals {
  vpc_id          = data.terraform_remote_state.base_network.outputs.base_network.vpc_id
  private_subnets = data.terraform_remote_state.base_network.outputs.base_network.private_subnets
  public_subnets  = data.terraform_remote_state.base_network.outputs.base_network.public_subnets
  PrivateAZ1      = data.terraform_remote_state.base_network.outputs.base_network.private_subnets[0]
  PrivateAZ2      = data.terraform_remote_state.base_network.outputs.base_network.private_subnets[1]
  PublicAZ1       = data.terraform_remote_state.base_network.outputs.base_network.public_subnets[0]
  PublicAZ2       = data.terraform_remote_state.base_network.outputs.base_network.public_subnets[1]
}

data "aws_caller_identity" "current" {}

# Data sources to setup Jenkins server
data "template_file" "jenkins-init" {
  template = file("scripts/jenkins-init.sh")
  vars = {
    DEVICE            = var.INSTANCE_DEVICE_NAME
    JENKINS_VERSION   = var.JENKINS_VERSION
    TERRAFORM_VERSION = var.TERRAFORM_VERSION
  }
}

data "template_cloudinit_config" "cloudinit-jenkins" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.jenkins-init.rendered
  }
}

# Data Source to get Ubuntu AMI for Jenkins Server
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

###############################################################################
# Security Groups
###############################################################################

resource "aws_security_group" "jenkins-securitygroup" {
  vpc_id      = local.vpc_id
  name        = "jenkins-securitygroup"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-securitygroup"
  }
}

resource "aws_security_group" "app-securitygroup" {
  vpc_id      = local.vpc_id
  name        = "app-securitygroup"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app-securitygroup"
  }
}

###############################################################################
# ECR Role - Jenkins
###############################################################################

resource "aws_iam_role" "jenkins-role" {
  name               = "jenkins-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "jenkins-role" {
  name = "jenkins-role"
  role = aws_iam_role.jenkins-role.name
}

resource "aws_iam_role_policy" "admin-policy" {
  name = "jenkins-admin-role-policy"
  role = aws_iam_role.jenkins-role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

###############################################################################
# Encrypt - EBS Volumes
###############################################################################

resource "aws_ebs_encryption_by_default" "encrypt" {
  enabled = true
}

###############################################################################
# EC2 Instance - Jenkins
###############################################################################

resource "aws_instance" "jenkins-instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = local.PublicAZ1
  vpc_security_group_ids = [aws_security_group.jenkins-securitygroup.id]
  key_name               = var.internal_key_pair
  user_data              = data.template_cloudinit_config.cloudinit-jenkins.rendered
  iam_instance_profile   = aws_iam_instance_profile.jenkins-role.name
}

resource "aws_ebs_volume" "jenkins-data" {
  availability_zone = "ap-southeast-2a"
  size              = 20
  type              = "gp2"
  tags = {
    Name = "jenkins-data"
  }
}

resource "aws_volume_attachment" "jenkins-data-attachment" {
  device_name  = var.INSTANCE_DEVICE_NAME
  volume_id    = aws_ebs_volume.jenkins-data.id
  instance_id  = aws_instance.jenkins-instance.id
  skip_destroy = true
}

resource "aws_instance" "app-instance" {
  count                  = var.APP_INSTANCE_COUNT
  ami                    = var.APP_INSTANCE_AMI
  instance_type          = "t2.micro"
  subnet_id              = local.PublicAZ1
  vpc_security_group_ids = [aws_security_group.app-securitygroup.id]
  key_name               = var.internal_key_pair
}
