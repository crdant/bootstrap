install_iaas_params () {
  cat <<PARAMS >> ${pcf_install_parameter_file}
aws_access_key_id: ${pcf_secret_access_key_id}
aws_secret_access_key: ${pcf_secret_access_key}
aws_az1: ${availability_zone_1}
aws_az2: ${availability_zone_2}
aws_az3: ${availability_zone_3}
aws_cert_arn: ${pcf_wildcard_cert_arn}
aws_key_name: ${default_key_name}
aws_region: ${region}
ROUTE_53_ZONE_ID: ${bootstrap_dns_zone_id}
S3_OUTPUT_BUCKET: ${pipeline_statefile_bucket}
PEM: ${private_key}
PARAMS
}

opsman_iaas_params () {
  cat <<PARAMS >> ${om_upgrade_parameter_file}
# AWS params
aws_access_key_id: ${pcf_secret_access_key_id}
aws_secret_access_key: ${pcf_secret_access_key}
aws_region: ${region}
aws_vpc_id: ${vpc}
PARAMS
}
