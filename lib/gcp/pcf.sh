params() {
  cat <<PARAMS > ${pcf_install_parameter_file}

  # GCP project to create the infrastructure in
  gcp_project_id: ${project}

  # Identifier to prepend to GCP infrastructure names/labels
  gcp_resource_prefix: pcf-${short_id}

  # GCP region
  gcp_region: ${region}

  # GCP Zones
  gcp_zone_1: ${availability_zone_1}
  gcp_zone_2: ${availability_zone_2}
  gcp_zone_3: ${availability_zone_3}

  # Storage Location
  gcp_storage_bucket_location: ${storage_location}

  terraform_statefile_bucket: ${terraform_statefile_bucket}

  # Elastic Runtime Domain
  pcf_ert_domain: ${pcf_subdomain} # This is the domain you will access ERT with
  opsman_domain_or_ip_address: opsman.${pcf_subdomain} # This should be your pcf_ert_domain with "opsman." as a prefix

  ert_errands_to_disable: none

  # PCF Operations Manager minor version to install
  opsman_major_minor_version: ^2\.1\..*$

  # PCF Elastic Runtime minor version to install
  ert_major_minor_version: ^2\.1\..*$

  # ops man client info not needed if we're using admin username/password that we have set earlier
  # but parameters need to be present
  opsman_client_id: ""
  opsman_client_secret: ""

  # networking options
  container_networking_nw_cidr: 10.254.32.0/22
  internet_connected: false
  networking_poe_ssl_certs: []
  opsman_trusted_certs: []
  routing_tls_termination: "load_balancer"
  routing_custom_ca_certificates: []
  security_acknowledgement: "X"

  # configure routing
  router_tls_ciphers: "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384"
  routing_disable_http: true

  # not using HA proxy, but need to have values for the pipeline to work
  haproxy_backend_ca:
  haproxy_forward_tls:
  haproxy_tls_ciphers:

  mysql_monitor_recipient_email: ${email} # Email address for sending mysql monitor notifications
  mysql_backups: s3   # Whether to enable MySQL backups. (disable|s3|scp)
  mysql_backups_s3_access_key_id: ((gcp_storage_access_key))
  mysql_backups_s3_bucket_name: ${mysql_backup_bucket}
  mysql_backups_s3_bucket_path:
  mysql_backups_s3_cron_schedule: ${mysql_backup_schedule}more
  mysql_backups_s3_endpoint_url: https://storage.googleapis.com
  mysql_backups_s3_secret_access_key: ((gcp_storage_secret_key))
  mysql_backups_scp_cron_schedule:
  mysql_backups_scp_destination:
  mysql_backups_scp_key:
  mysql_backups_scp_port:
  mysql_backups_scp_server:
  mysql_backups_scp_user:
PARAMS

  cat <<PARAMS > ${pcf_upgrade_parameter_file}
  product_version_regex: ^2\.1\..*$
  opsman_client_id: ""
  opsman_client_secret: ""
  opsman_domain_or_ip_address: ${opsman_domain_or_ip_address}
  iaas_type: ${iaas}
  product_slug: "elastic-runtime"
  product_globs: "*pivotal"
PARAMS

}
