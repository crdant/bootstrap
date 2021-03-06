install_iaas_params() {
  # GCP specific - figure out how to handle it
  safe set ${team_secret_root}/gcp_service_account_key value="$(cat ${pcf_key_file})"

  cat <<PARAMS >> ${pcf_install_parameter_file}

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
terraform_statefile_bucket: ${short_id}-terraform-state

# database
db_cloudsqldb_tier: db-f1-micro

# router - moved here because AWS needs a custom set
router_tls_ciphers: ECDHE-RSA-AES128-GCM-SHA256:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
PARAMS
}

opsman_iaas_params () {
  cat <<PARAMS >> ${om_upgrade_parameter_file}
# GCP params
gcp_project_id: ${project}
gcp_zone: ${availability_zone_1}
PARAMS
}
