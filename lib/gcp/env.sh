project=fe-cdantonio
account=${email}

stemcell_iaas="google-kvm"
region="us-east1"
storage_location="us"
availability_zone_1="${region}-d"
availability_zone_2="${region}-c"
availability_zone_3="${region}-b"

# TO DO: fixed up to env_id next time I tear down
plan_service_account_name=${subdomain_token}
plan_service_account="${plan_service_account_name}@${project}.iam.gserviceaccount.com"
plan_key_file="${key_dir}/${plan_service_account}.json"

service_account_name="${short_id}"
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"
key_file="${key_dir}/${service_account}.json"
