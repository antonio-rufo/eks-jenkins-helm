
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
    key     = "terraform.development.200compute.tfstate"
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
    bucket  = "162198556136-build-state-bucket-antonio-appmod-eks-helm"
    key     = "terraform.development.000base.tfstate"
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

# ###############################################################################
# # Jenkins
# ###############################################################################
# # Data sources to setup Jenkins server
# data "template_file" "jenkins-init" {
#   template = file("scripts/jenkins-init.sh")
#   vars = {
#     DEVICE            = var.INSTANCE_DEVICE_NAME
#     JENKINS_VERSION   = var.JENKINS_VERSION
#     TERRAFORM_VERSION = var.TERRAFORM_VERSION
#   }
# }
#
# data "template_cloudinit_config" "cloudinit-jenkins" {
#   gzip          = false
#   base64_encode = false
#
#   part {
#     content_type = "text/x-shellscript"
#     content      = data.template_file.jenkins-init.rendered
#   }
# }

# ###############################################################################
# # Docker
# ###############################################################################
# # Data sources to setup Jenkins server
# data "template_file" "docker-init" {
#   template = file("scripts/docker-init.sh")
# }
#
# data "template_cloudinit_config" "cloudinit-docker" {
#   gzip          = false
#   base64_encode = false
#
#   part {
#     content_type = "text/x-shellscript"
#     content      = data.template_file.docker-init.rendered
#   }
# }

###############################################################################
# EKSCTL
###############################################################################
# Data sources to setup Jenkins server
data "template_file" "eks-init" {
  template = file("scripts/eks-init.sh")
}

data "template_cloudinit_config" "cloudinit-eks" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.eks-init.rendered
  }
}

# ###############################################################################
# # Security Groups - Jenkins
# ###############################################################################
# resource "aws_security_group" "jenkins-securitygroup" {
#   vpc_id      = local.vpc_id
#   name        = "jenkins-securitygroup"
#   description = "security group that allows ssh, http and all egress traffic"
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "jenkins-securitygroup"
#   }
# }

# ###############################################################################
# # Security Groups - Docker
# ###############################################################################
# resource "aws_security_group" "docker-securitygroup" {
#   vpc_id      = local.vpc_id
#   name        = "docker-securitygroup"
#   description = "security group that allows ssh and all egress traffic"
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "docker-securitygroup"
#   }
# }

###############################################################################
# Security Groups - Docker
###############################################################################
resource "aws_security_group" "eks-securitygroup" {
  vpc_id      = local.vpc_id
  name        = "eks-securitygroup"
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
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-securitygroup"
  }
}

# ###############################################################################
# # IAM Role - Jenkins
# ###############################################################################
# resource "aws_iam_role" "jenkins-role" {
#   name               = "jenkins-role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
#
# }
#
# resource "aws_iam_instance_profile" "jenkins-role" {
#   name = "jenkins-role"
#   role = aws_iam_role.jenkins-role.name
# }
#
# resource "aws_iam_role_policy" "admin-policy" {
#   name = "jenkins-admin-role-policy"
#   role = aws_iam_role.jenkins-role.id
#
#   policy = <<-EOF
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": [
#           "*"
#         ],
#         "Effect": "Allow",
#         "Resource": "*"
#       }
#     ]
#   }
#   EOF
# }

# ###############################################################################
# # IAM Role - Docker
# ###############################################################################
# resource "aws_iam_role" "docker-role" {
#   name               = "docker-role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
#
# }
#
# resource "aws_iam_instance_profile" "docker-role" {
#   name = "docker-role"
#   role = aws_iam_role.docker-role.name
# }
#
# resource "aws_iam_role_policy" "docker-admin-policy" {
#   name = "docker-admin-role-policy"
#   role = aws_iam_role.docker-role.id
#
#   policy = <<-EOF
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": [
#           "*"
#         ],
#         "Effect": "Allow",
#         "Resource": "*"
#       }
#     ]
#   }
#   EOF
# }

###############################################################################
# IAM Role - EKS
###############################################################################
resource "aws_iam_role" "eks-role" {
  name               = "eks-role"
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

resource "aws_iam_instance_profile" "eks-role" {
  name = "eks-role"
  role = aws_iam_role.eks-role.name
}

resource "aws_iam_role_policy" "eks-admin-policy" {
  name = "eks-admin-role-policy"
  role = aws_iam_role.eks-role.id

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

# ###############################################################################
# # EC2 Instance - Jenkins
# ###############################################################################
# resource "aws_instance" "jenkins-instance" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.small"
#   subnet_id              = local.PublicAZ1
#   vpc_security_group_ids = [aws_security_group.jenkins-securitygroup.id]
#   key_name               = var.internal_key_pair
#   user_data              = data.template_cloudinit_config.cloudinit-jenkins.rendered
#   iam_instance_profile   = aws_iam_instance_profile.jenkins-role.name
#
#   tags = {
#     Name = "Docker-Server"
#   }
# }
#
# resource "aws_ebs_volume" "jenkins-data" {
#   availability_zone = "ap-southeast-2a"
#   size              = 20
#   type              = "gp2"
#   tags = {
#     Name = "jenkins-data"
#   }
# }
#
# resource "aws_volume_attachment" "jenkins-data-attachment" {
#   device_name  = var.INSTANCE_DEVICE_NAME
#   volume_id    = aws_ebs_volume.jenkins-data.id
#   instance_id  = aws_instance.jenkins-instance.id
#   skip_destroy = true
# }

# ###############################################################################
# # EC2 Instance - Docker
# ###############################################################################
# resource "aws_instance" "docker-instance" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.small"
#   subnet_id              = local.PublicAZ1
#   vpc_security_group_ids = [aws_security_group.docker-securitygroup.id]
#   key_name               = var.internal_key_pair
#   user_data              = data.template_cloudinit_config.cloudinit-docker.rendered
#   iam_instance_profile   = aws_iam_instance_profile.docker-role.name
#
#   tags = {
#     Name = "Docker-Server"
#   }
# }

###############################################################################
# EC2 Instance - EKSCTL
###############################################################################
resource "aws_instance" "eks-instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = local.PublicAZ1
  vpc_security_group_ids = [aws_security_group.eks-securitygroup.id]
  key_name               = var.internal_key_pair
  user_data              = data.template_cloudinit_config.cloudinit-eks.rendered
  iam_instance_profile   = aws_iam_instance_profile.eks-role.name

  tags = {
    Name = "EKS-Server"
  }
}
