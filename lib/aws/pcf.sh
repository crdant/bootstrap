install_iaas_params () {
  safe_auth
  safe set ${team_secret_root}/aws_access_key_id value="${pcf_secret_access_key_id}"
  safe set ${team_secret_root}/aws_secret_access_key value="${pcf_secret_access_key}"

  safe set ${deploy_secret_root}/PEM value="$(cat $pcf_private_key_file)"
  safe set ${deploy_secret_root}/mysql_backups_s3_access_key_id value=${pcf_secret_access_key_id}
  safe set ${deploy_secret_root}/mysql_backups_s3_secret_access_key value=${pcf_secret_access_key}
  safe set ${deploy_secret_root}/director_certificates value="$(cat ${ca_cert_file})"

  cat <<PARAMS >> ${pcf_install_parameter_file}
aws_az1: ${availability_zone_1}
aws_az2: ${availability_zone_2}
aws_az3: ${availability_zone_3}
aws_cert_arn: ${pcf_wildcard_cert_arn}
aws_key_name: ${env_id}-pcf-key
aws_region: ${region}
mysql_backups: s3
mysql_backups_s3_bucket_name: ${mysql_backup_bucket}
mysql_backups_s3_bucket_path: mysql_backups
mysql_backups_s3_cron_schedule: "22 4 * * 0"
mysql_backups_s3_endpoint_url: https://s3.${region}.amazonaws.com
ROUTE_53_ZONE_ID: ${pcf_dns_zone_id}
# For terraform state file (http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region)
S3_ENDPOINT: https://s3.${region}.amazonaws.com
S3_OUTPUT_BUCKET: ${pipeline_statefile_bucket}
router_tls_ciphers: TLS_DHE_RSA_WITH_AES_256_GCM_SHA384:TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
PARAMS
}

opsman_iaas_params () {
  cat <<PARAMS >> ${om_upgrade_parameter_file}
# AWS params
aws_access_key_id: ${pcf_secret_access_key_id}
aws_secret_access_key: ${pcf_secret_access_key}
aws_region: ${region}
aws_vpc_id: vpc-1999b260
PARAMS
}
