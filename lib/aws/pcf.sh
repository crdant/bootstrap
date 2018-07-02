
install_iaas_params () {
  safe_auth
  safe set ${team_secret_root}/aws_access_key_id value="${pcf_secret_access_key_id}"
  safe set ${team_secret_root}/aws_secret_access_key value="${pcf_secret_access_key}"

  safe set ${deploy_secret_root}/PEM value="$(cat $pcf_private_key_file)"
  safe set ${deploy_secret_root}/mysql_backups_s3_access_key_id value=${pcf_secret_access_key_id}
  safe set ${deploy_secret_root}/mysql_backups_s3_secret_access_key value=${pcf_secret_access_key}
  safe set ${deploy_secret_root}/director_certificates value="$(cat ${ca_cert_file})"

  cat <<PARAMS >> ${pcf_install_parameter_file}
# AWS basics
aws_az1: ${availability_zone_1}
aws_az2: ${availability_zone_2}
aws_az3: ${availability_zone_3}
aws_cert_arn: ${pcf_wildcard_cert_arn}
aws_key_name: ${env_id}-pcf-key
aws_region: ${region}
# networking
amis_nat: ami-303b1458
dynamic_services_subnet_cidr_az1: 172.24.112.0/22
dynamic_services_subnet_cidr_az2: 172.24.128.0/22
dynamic_services_subnet_cidr_az3: 172.24.144.0/22
dynamic_services_subnet_reserved_ranges_z1: 172.24.112.0 - 172.24.112.10
dynamic_services_subnet_reserved_ranges_z2: 172.24.128.0 - 172.24.128.10
dynamic_services_subnet_reserved_ranges_z3: 172.24.144.0 - 172.24.144.10
ert_subnet_cidr_az1: 172.24.16.0/20
ert_subnet_cidr_az2: 172.24.32.0/20
ert_subnet_cidr_az3: 172.24.48.0/20
ert_subnet_reserved_ranges_z1: 172.24.16.0 - 172.24.16.10
ert_subnet_reserved_ranges_z2: 172.24.32.0 - 172.24.32.10
ert_subnet_reserved_ranges_z3: 172.24.48.0 - 172.24.48.10
infra_subnet_cidr_az1: 172.24.6.0/24
infra_subnet_reserved_ranges_z1: 172.24.6.0 - 172.24.6.10
nat_ip_az1: 172.24.0.6
nat_ip_az2: 172.24.1.6
nat_ip_az3: 172.24.2.6
opsman_ip_az1: 172.24.0.7
opsman_allow_ssh_cidr_ranges: 0.0.0.0/0
opsman_allow_https_cidr_ranges: 0.0.0.0/0
public_subnet_cidr_az1: 172.24.0.0/24
public_subnet_cidr_az2: 172.24.1.0/24
public_subnet_cidr_az3: 172.24.2.0/24
rds_subnet_cidr_az1: 172.24.3.0/24
rds_subnet_cidr_az2: 172.24.4.0/24
rds_subnet_cidr_az3: 172.24.5.0/24
services_subnet_cidr_az1: 172.24.64.0/20
services_subnet_cidr_az2: 172.24.80.0/20
services_subnet_cidr_az3: 172.24.96.0/20
services_subnet_reserved_ranges_z1: 172.24.64.0 - 172.24.64.10
services_subnet_reserved_ranges_z2: 172.24.80.0 - 172.24.80.10
services_subnet_reserved_ranges_z3: 172.24.96.0 - 172.24.96.10
vpc_cidr: 172.24.0.0/16
# MySQL
mysql_backups: s3
mysql_backups_s3_bucket_name: ${mysql_backup_bucket}
mysql_backups_s3_bucket_path: mysql_backups
mysql_backups_s3_cron_schedule: "22 4 * * 0"
mysql_backups_s3_endpoint_url: https://s3.${region}.amazonaws.com
ROUTE_53_ZONE_ID: ${pcf_dns_zone_id}
# For terraform state file (http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region)
S3_ENDPOINT: https://s3.${region}.amazonaws.com
S3_OUTPUT_BUCKET: ${pipeline_statefile_bucket}

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
