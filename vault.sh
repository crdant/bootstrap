#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

vault_version=0.6.2
vault_checksum=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
vault_host="vault.${subdomain}"
vault_static_ip=10.0.31.195
vault_port=8200
vault_addr=https://${vault_host}:${vault_port}

export vault_cert_file=${key_dir}/vault-${env_id}.crt
export vault_key_file=${key_dir}/vault-${env_id}.key

ssl_certificates () {
  echo "Creating SSL certificate..."

  common_name="${vault_host}"
  org_unit="Vault"

  create_certificate ${common_name} ${org_unit} --domains "${vault_host}" --ips ${vault_static_ip}
}

stemcell () {
  bosh -n -e ${env_id} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

releases () {
  bosh -n -e ${env_id} upload-release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease?v=${vault_version} --sha1 ${vault_checksum}
}

interpolate () {
  local manifest=${manifest_dir}/vault.yml
  bosh interpolate ${manifest} --var vault-static-ip="${vault_static_ip}" --var-file vault-cert="${vault_cert_file}" --var-file vault-key="${vault_key_file}"
}

lbs () {
  echo "Creating load balancer..."
  local address_name="${env_id}-vault"
  local load_balancer_name="${env_id}-vault"
  gcloud compute --project "${project}" addresses create "${address_name}" --region "${region}" --no-user-output-enabled
  gcloud compute --project "${project}" target-pools create "${load_balancer_name}" --description "Target pool for load balancing Vault access" --region "${region}" --no-user-output-enabled
  gcloud compute --project "${project}" forwarding-rules create "${load_balancer_name}" --description "Forwarding rule for load balancing Vault access." --region "${region}" --address "https://www.googleapis.com/compute/v1/projects/${project}/regions/${region}/addresses/${address_name}" --ip-protocol "TCP" --ports "8200" --target-pool "${load_balancer_name}" --no-user-output-enabled
}

dns () {
  echo "Configuring DNS..."
  local address_name="${env_id}-vault"
  local address=$(gcloud compute --project ${project} addresses describe "${address_name}" --format json --region "${region}"  | jq --raw-output ".address")
  local transaction_file="${workdir}/vault-dns-transaction-${pcf_dns_zone}.xml"

  gcloud dns record-sets transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets transaction add -z "${dns_zone}" --name "${vault_host}" --ttl "${dns_ttl}" --type A "${address}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
}

update_cloud_config () {
  bosh -e ${env_id} cloud-config |
    bosh interpolate -o etc/add-lb.yml -v env-id="${env_id}" -v job="vault" - |
    bosh -n -e ${env_id} update-cloud-config -
}

deploy () {
  local manifest=${manifest_dir}/vault.yml
  bosh -n -e ${env_id} -d vault deploy ${manifest} \
    --var vault-static-ip="${vault_static_ip}" --var vault-addr=${vault_addr} --var-file vault-cert="${vault_cert_file}" --var-file vault-key="${vault_key_file}"
}

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-vault" --allow="tcp:${vault_port}"  --source-ranges="0.0.0.0/0" --target-tags="vault" --network="${env_id}-network "
}

tunnel () {
  ssh -fnNT -L 8200:${vault_static_ip}:8200 jumpbox@${jumpbox} -i $BOSH_GW_PRIVATE_KEY
}

unseal() {
  # unseal the vault
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[0]' ${key_dir}/vault_secrets.json`
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[1]' ${key_dir}/vault_secrets.json`
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[2]' ${key_dir}/vault_secrets.json`
}

init () {
  # initialize the vault using the API directly to parse the JSON
  initialization=`cat ${etc_dir}/vault_init.json`
  curl -qs --cacert ${vault_cert_file} -X PUT "${vault_addr}/v1/sys/init" -H "Accept: application/json" -H "Content-Type: application/json" -d "${initialization}" | jq '.' >${key_dir}/vault_secrets.json
  unseal
}

stop () {
  bosh -n -e ${env_id} -d vault update-resurrection off
  for cid in `bosh -n -e ${env_id} -d vault vms --json | jq --raw-output '.Tables[].Rows[].vm_cid'`; do
    bosh -n -e ${env_id} -d vault delete-vm ${cid}
  done
}

start () {
  deploy
  bosh -n -e ${env_id} -d vault update-resurrection on
}

teardown () {
  bosh -n -e ${env_id} -d vault delete-deployment
  gcloud --project "${project}" compute firewall-rules delete "${env_id}-vault"
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      certificates )
        ssl_certificates
        ;;
      security )
        ssl_certificates
        ;;
      stemcell )
        stemcell
        ;;
      release )
        release
        ;;
      interpolate )
        interpolate
        ;;
      lbs )
        lbs
        ;;
      dns )
        dns
        ;;
      cloud-config )
        update_cloud_config
        ;;
      deploy )
        deploy
        ;;
      firewall )
        firewall
        ;;
      tunnel )
        tunnel
        ;;
      init )
        init
        ;;
      start )
        start
        ;;
      stop )
        stop
        ;;
      unseal )
        unseal
        ;;
      teardown )
        teardown
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
  done
  exit
fi

ssl_certificates
stemcell
releases
lbs
deploy
firewall
tunnel
init
