iam_accounts() {
  echo "Configuring service accounts..."
  gcloud iam service-accounts --project "${project}" create "${service_account_name}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" keys create "${key_file}"  --iam-account "${service_account}" --no-user-output-enabled
  chmod 600 ${key_file}
  gcloud projects add-iam-policy-binding "${project}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id --state-dir ${state_dir}`
  gcloud --project "${project}" compute firewall-rules update ${env_id}-bosh-open --target-tags=${env_id}-bosh-director,${env_id}-internal
}

dns () {
  # TODO: move this to prepare.sh
  gcloud dns managed-zones --project ${project} create ${dns_zone} --dns-name "${subdomain}." --description "Zone for ${subdomain}"

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"
}
