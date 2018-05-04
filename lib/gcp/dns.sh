add_dns_host() {
  local dns_zone="${1}"
  local hostname="${2}"
  local address="${3}"
  local transaction_file="${workdir}/${hostname}-dns-transaction-${dns_zone}.xml"

  gcloud dns record-sets --project "${project}" transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets --project ${project} transaction add -z "${dns_zone}" --name "${hostname}" --ttl "${dns_ttl}" --type A "${address}" --transaction-file="${transaction_file}"
  gcloud dns record-sets --project ${project} transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}"

  rm "${transaction_file}"
}

add_dns_alias() {
  local zone_id="${1}"
  local alias="${2}"
  local host="${3}"
  local transaction_file="${workdir}/${hostname}-dns-transaction-${dns_zone}.xml"

  gcloud dns record-sets --project "${project}" transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets --project ${project} transaction add -z "${dns_zone}" --name "${hostname}" --ttl "${dns_ttl}" --type CNAME "${alias}" --transaction-file="${transaction_file}"
  gcloud dns record-sets --project ${project} transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}"

  rm "${transaction_file}"
}
