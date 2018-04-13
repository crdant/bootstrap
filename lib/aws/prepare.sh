iam_accounts() {
  echo "Configuring IAM account..."
  aws iam create-user --user-name ${iam_account_name} > ${key_file}
  access_key_id=$(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  secret_access_key=$(cat ${key_file} | jq --raw-output '.AccessKey.SecretAccessKey')
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id --state-dir ${state_dir}`
  gcloud --project "${project}" compute firewall-rules update ${env_id}-bosh-open --target-tags=${env_id}-bosh-director,${env_id}-internal
}

dns () {
  gcloud dns managed-zones --project ${project} create ${dns_zone} --dns-name "${subdomain}." --description "Zone for ${subdomain}"

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"
}
