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
output "jenkins-ip" {
  value = [aws_instance.jenkins-instance.*.public_ip]
}

output "app-ip" {
  value = [aws_instance.app-instance.*.public_ip]
}
