#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"
. "${BASEDIR}/lib/secrets.sh"
. "${BASEDIR}/lib/certificates.sh"

stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585
concourse_version=3.5.0
concourse_checksum=65a974b3831bb9908661a5ffffbe456e10185149
garden_version=1.6.0
garden_checksum=58fbc64aff303e6d76899441241dd5dacef50cb7

concourse_host="concourse.${subdomain}"
concourse_url="https://${concourse_host}"
concourse_user=admin

concourse_cert_cn="${concourse_host}"
concourse_key_file="${ca_dir}/${concourse_host}.key"
concourse_cert_file="${ca_dir}/${concourse_host}.crt"

ssl_certificates () {
  echo "Creating SSL certificate..."

  common_name="${concourse_cert_cn}"
  org_unit="Continuous Delivery"
  create_certificate "${common_name}" "${org_unit}"

  echo "SSL certificate created and stored at ${ca_dir}/${common_name}.crt, private key stored at ${ca_dir}/${common_name}.key."
}

stemcell () {
  bosh -e "${env_id}" upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

releases () {
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/concourse/concourse?v=${concourse_version} --sha1 ${concourse_checksum}
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v=${garden_version} --sha1 ${garden_checksum}
}

safe_auth () {
  safe_auth_bootstrap
}

vars () {
  atc_vault_token=`jq --raw-output '.auth.client_token' ${key_dir}/atc-${env_id}-token.json`
  vault_cert_file=${ca_dir}/vault.${subdomain}.crt
  concourse_password=`safe get secret/bootstrap/concourse/admin:value`
  cat <<VAR_ARGUMENTS
    --var concourse-url="${concourse_url}" --var concourse-user=${concourse_user} --var concourse-password=${concourse_password} --var atc-vault-token=${atc_vault_token}
    --var-file atc-cert-file=${concourse_cert_file} --var-file atc-key-file=${concourse_key_file} --var-file vault-cert-file=${vault_cert_file}
VAR_ARGUMENTS
}

interpolate () {
  local manifest=${manifest_dir}/concourse.yml
  bosh interpolate "${manifest}" `vars`
}

deploy () {
  local manifest=${manifest_dir}/concourse.yml
  admin_password=`generate_passphrase 4`
  safe_auth_bootstrap
  safe set secret/bootstrap/concourse/admin value="${admin_password}"
  bosh -n -e "${env_id}" -d concourse deploy "${manifest}" `vars`
}

lbs () {
  bbl create-lbs --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" --type concourse --key ${lb_key_file} --cert ${lb_cert_file}
}

dns() {
  echo "Setting up DNS..."

  local transaction_file="${workdir}/concourse-dns-transaction-${dns_zone}.xml"

  gcloud dns record-sets --project "${project}" transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled

  # set up the load balancer in DNS
  lb_address=`gcloud compute --project ${project} forwarding-rules describe ${env_id}-concourse-https --region ${region} --format json | jq --raw-output '.IPAddress'`
  gcloud dns record-sets --project ${project} transaction add -z "${dns_zone}" --name "${concourse_host}" --ttl "${dns_ttl}" --type A "${lb_address}" --transaction-file="${transaction_file}"
  gcloud dns record-sets --project ${project} transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}"

  rm "${transaction_file}"
}

login () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
  concourse_password=`safe get secret/bootstrap/concourse/admin:value`
  fly --target ${env_id} login --team-name main --ca-cert ${ca_cert_file} --concourse-url=${concourse_url} --username=${concourse_user} --password=${concourse_password}
}

url () {
  echo ${concourse_url}
}

stop () {
  bosh -e $env_id
  bosh -n -e ${env_id} -d concourse update-resurrection off
  for cid in `bosh -n -e ${env_id} -d concourse vms --json | jq --raw-output '.Tables[].Rows[].vm_cid'`; do
    bosh -n -e ${env_id} -d concourse delete-vm ${cid}
  done
}

start () {
  deploy
  bosh -n -e ${env_id} -d concourse update-resurrection on
}

teardown () {
  bosh -n -e "${env_id}" -d concourse delete-deployment

  # delete load balancer in DNS
  local transaction_file="${workdir}/dns-transaction-${dns_zone}.xml"
  gcloud dns record-sets --project "${project}" transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
  lb_address=`gcloud compute --project ${project} forwarding-rules describe ${env_id}-concourse-https --region ${region} --format json | jq --raw-output '.IPAddress'`
  gcloud dns record-sets --project ${project} transaction remove -z "${dns_zone}" --name "${concourse_host}" --ttl "${dns_ttl}" --type A "${lb_address}" --transaction-file="${transaction_file}"
  gcloud dns record-sets --project ${project} transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}"

  bbl delete-lbs --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"
}


modernize_pipeline() {
  local pipeline_file=${1}
  sed -i -e 's/{{/((/g' "${pipeline_file}"
  sed -i -e 's/}}/))/g' "${pipeline_file}"
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
      deploy )
        deploy
        ;;
      upgrade )
        stemcell
        releases
        deploy
        ;;
      lbs )
        lbs
        ;;
      dns )
        dns
        ;;
      init )
        ;;
      login )
        login
        ;;
      start )
        start
        ;;
      stop )
        stop
        ;;
      teardown )
        teardown
        ;;
      url )
        url
        ;;
      interpolate )
        interpolate
        ;;
      modernize | modernize_pipeline )
        modernize_pipeline ${2}
        shift
        ;;
      safe_auth | auth )
        safe_auth
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
dns
login
