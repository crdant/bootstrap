#!/bin/bash

set -eu

copy_templates () {
  cp -R pcf-pipelines-base/* pcf-pipelines
  cp bootstrap/pipelines/tasks/harden-network/${iaas}/terraform/*.tf pcf-pipelines/install-pcf/${iaas}/terraform
}

get_ips() {
  cloudfront_ips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq --arg region "${region}" '[ .prefixes[] | select(.service=="CLOUDFRONT" and .region==$region) | .ip_prefix  ]')
  ec2_ips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq --arg region "${region}" '[ .prefixes[] | select(.service=="EC2" and .region==$region) |  .ip_prefix  ]')
  github_ips=$(curl -s https://api.github.com/meta | jq '.git')
}

# write the variables to a template with default values
# this is a hack right due to https://github.com/hashicorp/terraform/issues/16197
write_var_file() {
  var_file=pcf-pipelines/install-pcf/${iaas}/terraform/harden-vars.tf
  cat <<TFVARS > ${var_file}
/*
  Whitelist variables
 */

variable "github_ips" {
  type = "list"
  default = ${github_ips}
}

variable "ec2_ips" {
  type = "list"
  default = ${ec2_ips}
}

variable "cloudfront_ips" {
  type = "list"
  default = ${cloudfront_ips}
}
TFVARS
}

copy_templates
get_ips
write_var_file
