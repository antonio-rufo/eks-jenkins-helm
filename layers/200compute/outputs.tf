###############################################################################
# State Import Example
# terraform output state_import_example
###############################################################################
output "state_import_example" {
  description = "An example to use this layers state in another."

  value = <<EOF

  data "terraform_remote_state" "compute" {
    backend = "s3"

    config = {
      bucket  = "${data.terraform_remote_state.main_state.outputs.state_bucket_id}"
      key     = "terraform.${lower(var.environment)}.200compute.tfstate"
      region  = "${data.terraform_remote_state.main_state.outputs.state_bucket_region}"
      encrypt = "true"
    }
  }
EOF
}

###############################################################################
# Jenkins instance IP address
###############################################################################
output "docker-instance-ip" {
  value = [aws_instance.docker-instance.*.public_ip]
}
