lbs () {
  echo "Creating load balancer..."
  local address_name="${env_id}-vault"
  local load_balancer_name="${env_id}-vault"
  gcloud compute --project "${project}" addresses create "${address_name}" --region "${region}" --no-user-output-enabled
  gcloud compute --project "${project}" target-pools create "${load_balancer_name}" --description "Target pool for load balancing Vault access" --region "${region}" --no-user-output-enabled
  gcloud compute --project "${project}" forwarding-rules create "${load_balancer_name}" --description "Forwarding rule for load balancing Vault access." --region "${region}" --address "https://www.googleapis.com/compute/v1/projects/${project}/regions/${region}/addresses/${address_name}" --ip-protocol "TCP" --ports "8200" --target-pool "${load_balancer_name}" --no-user-output-enabled
  update_cloud_config
}

dns () {
  echo "Configuring DNS..."
  local address_name="${env_id}-vault"
  local address=$(gcloud compute --project ${project} addresses describe "${address_name}" --format json --region "${region}"  | jq --raw-output ".address")
  local transaction_file="${workdir}/vault-dns-transaction-${pcf_dns_zone}.xml"

  gcloud dns record-sets transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled --project ${project}
  gcloud dns record-sets transaction add -z "${dns_zone}" --name "${vault_host}" --ttl "${dns_ttl}" --type A "${address}" --transaction-file="${transaction_file}" --no-user-output-enabled --project ${project}
  gcloud dns record-sets transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled --project ${project}
}

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-vault" --allow="tcp:${vault_port}"  --source-ranges=${vault_access_cidr} --target-tags="vault" --network="${env_id}-network "
}

teardown_infra() {
  gcloud --project "${project}" compute firewall-rules delete "${env_id}-vault"
}
