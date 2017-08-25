#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"

stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585
concourse_version=3.4.0
concourse_checksum=e262b0fb209df6134ea15917e2b9b8bfb8d0d0d1
garden_version=1.6.0
garden_checksum=58fbc64aff303e6d76899441241dd5dacef50cb7

export concourse_host="concourse.${subdomain}"
export concourse_url="https://${concourse_host}"
export concourse_user=admin
export atc_key_file="${key_dir}/atc-${env_id}.key"
export atc_cert_file="${key_dir}/atc-${env_id}.crt"

ssl_certificates () {
  lb_key_file="${key_dir}/web-${env_id}.key"
  lb_cert_file="${key_dir}/web-${env_id}.crt"

  echo "Creating SSL certificate for load balancers..."

  common_name="*.${subdomain}"
  country="US"
  state="MA"
  city="Cambridge"
  organization="${domain}"
  org_unit="Continuous Delivery"
  email="${account}"
  subject="/C=${country}/ST=${state}/L=${city}/O=${organization}/OU=${org_unit}/CN=${common_name}/emailAddress=${email}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${lb_key_file}" -out "${lb_cert_file}" -subj "${subject}" > /dev/null

  echo "SSL certificate for load balanacers created and stored at ${key_dir}/${env_id}.crt, private key stored at ${key_dir}/${env_id}.key."

  echo "Creating SSL certificate for ATC..."

  common_name="*.${subdomain}"
  country="US"
  state="MA"
  city="Cambridge"
  organization="${domain}"
  org_unit="Continuous Delivery"
  email="${account}"
  subject="/C=${country}/ST=${state}/L=${city}/O=${organization}/OU=${org_unit}/CN=${common_name}/emailAddress=${email}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${atc_key_file}" -out "${atc_cert_file}" -subj "${subject}" > /dev/null
}

stemcell () {
  bosh -e "${env_id}" upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

releases () {
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/concourse/concourse?v=${concourse_version} --sha1 ${concourse_checksum}
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v=${garden_version} --sha1 ${garden_checksum}
}

safe_auth () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}

prepare_manifest () {
  local manifest=${workdir}/concourse.yml
  export atc_vault_token=`jq --raw-output '.auth.client_token' ${key_dir}/atc-${env_id}-token.json`
  export vault_cert_file=${key_dir}/vault-${env_id}.crt
  safe_auth
  safe set secret/bootstrap/concourse/admin value=`generate_passphrase 4`
  export concourse_password=`safe get secret/bootstrap/concourse/admin:value`

  spruce merge --prune tls ${manifest_dir}/concourse.yml > $manifest
}

deploy () {
  local manifest=${workdir}/concourse.yml
  bosh -n -e "${env_id}" -d concourse deploy "${manifest}"
}

lbs () {
  bbl create-lbs --type concourse --key ${lb_key_file} --cert ${lb_cert_file}
}

dns() {
  echo "Setting up DNS..."

  local transaction_file="${workdir}/dns-transaction-${dns_zone}.xml"
  gcloud dns managed-zones --project ${project} create ${dns_zone} --dns-name "${subdomain}." --description "Zone for ${subdomain}"

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"

  gcloud dns record-sets --project "${project}" transaction start -z "${dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled

  # set up the load balancer in DNS
  lb_address=`gcloud compute --project ${project} forwarding-rules describe ${env_id}-concourse-https --region ${region} --format json | jq --raw-output '.IPAddress'`
  gcloud dns record-sets --project ${project} transaction add -z "${dns_zone}" --name "${concourse_host}" --ttl "${dns_ttl}" --type A "${lb_address}" --transaction-file="${transaction_file}"
  gcloud dns record-sets --project ${project} transaction execute -z "${dns_zone}" --transaction-file="${transaction_file}"
}

login () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
  concourse_password=`safe get secret/bootstrap/concourse/admin:value`
  fly --target ${env_id} login --team-name main --ca-cert ${key_dir}/atc-${env_id}.crt --concourse-url=${concourse_url} --username=${concourse_user} --password=${concourse_password}
}

url () {
  echo ${concourse_url}
}

teardown () {
  bosh -n -e "${env_id}" -d concourse delete-deployment
  bbl delete-lbs
  gcloud dns managed-zones --project ${project} delete ${dns_zone}
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
      manifest )
        prepare_manifest
        ;;
      deploy )
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
      teardown )
        teardown
        ;;
      url )
        url
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
prepare_manifest
deploy
lbs
dns
login
