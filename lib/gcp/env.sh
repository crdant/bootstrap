project=fe-cdantonio

region="us-east4"
storage_location="us"
availability_zone_1="${region}-f"
availability_zone_2="${region}-c"
availability_zone_3="${region}-b"

# TO DO: fixed up to env_id next time I tear down
service_account_name=`echo ${subdomain} | tr . -`
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"
key_file="${key_dir}/${project}-${service_account_name}.json"