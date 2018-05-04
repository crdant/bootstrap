dns() {
  echo "Setting up DNS..."
  local address="$(gcloud compute --project ${project} forwarding-rules describe ${name} --region ${region} --format json | jq --raw-output '.IPAddress')"
  add_dns_host ${dns_zone_id} ${concourse_host} ${address} "Bootstrap concourse for ${env_id}"
}
