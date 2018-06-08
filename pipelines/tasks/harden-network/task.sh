#!/bin/bash

set -eu

var_file=pcf-pipelines/install-pcf/${iaas}/terraform/harden.auto.tfvars

copy_templates () {
  cp -R pcf-pipelines-base/* pcf-pipelines
  cp bootstrap/pipelines/tasks/terraform/${iaas}/*.tf pcf-pipelines/install-pcf/${iaas}/terraform
}

get_ips() {
  cloudfront_ips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq --arg region "${region}" '[ .prefixes[] | select(.service=="CLOUDFRONT" and .region==$region) | .ip_prefix  ]')
  ec2_ips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq --arg region "${region}" '[ .prefixes[] | select(.service=="EC2" and .region==$region) |  .ip_prefix  ]')
  github_ips=$(curl -s https://api.github.com/meta | jq '.git')
}

write_var_file() {
  cat <<TFVARS > ${var_file}
github_ips=${github_ips}

ec2_ips=${ec2_ips}

cloudfront_ips=${cloudfront_ips}
TFVARS
}

copy_templates
get_ips
write_var_file
