###############################################################################
# State Import Example
# terraform output state_import_example
###############################################################################
output "state_import_example" {
  description = "An example to use this layers state in another."

  value = <<EOF

  data "terraform_remote_state" "base_network" {
    backend = "s3"

    config = {
      bucket  = "${data.terraform_remote_state.main_state.outputs.state_bucket_id}"
      key     = "terraform.${lower(var.environment)}.000base.tfstate"
      region  = "${data.terraform_remote_state.main_state.outputs.state_bucket_region}"
      encrypt = "true"
    }
  }
EOF
}

###############################################################################
# Base Network Output
###############################################################################
output "base_network" {
  description = "base_network Module Output"
  value       = module.base_network
}

###############################################################################
# NAT Gateways
###############################################################################

output "base_network_nat_gateway_eip" {
  description = "The NAT gateway EIP(s) of the Base Network."
  value       = module.base_network.nat_gateway_eip
}

output "base_network_private_route_tables" {
  description = "The private route tables of the Base Network."
  value       = module.base_network.private_route_tables
}

output "base_network_private_subnets" {
  description = "The private subnets of the Base Network."
  value       = module.base_network.private_subnets
}

output "base_network_public_route_tables" {
  description = "The public route tables of the Base Network."
  value       = module.base_network.public_route_tables
}

output "base_network_public_subnets" {
  description = "The public subnets of the Base Network."
  value       = module.base_network.public_subnets
}

output "base_network_vpc_id" {
  description = "The VPC ID of the Base Network."
  value       = module.base_network.vpc_id
}
