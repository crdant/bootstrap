#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"
. "${BASEDIR}/lib/secrets.sh"

stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

concourse_version=3.4.0
concourse_checksum=e262b0fb209df6134ea15917e2b9b8bfb8d0d0d1
garden_version=1.6.0
garden_checksum=58fbc64aff303e6d76899441241dd5dacef50cb7

windows_stemcell_version=1200.3
windows_stemcell_checksum=1b6178873ba57e87a4cae74b9620227cc2c26518
windows_worker_version=3.4.1
windows_worker_checksum=5afcaa7a21be8c2837ec2b1ed9b545b6414d3722
windows_utilities_release_repository=https://github.com/cloudfoundry-incubator/windows-utilities-release
windows_utilities_version=0.3.0+dev.1
rdp_port=3389

concourse_host="concourse.${subdomain}"
concourse_url="https://${concourse_host}"
concourse_web_static_ip=10.0.31.198
concourse_user=admin
atc_key_file="${key_dir}/atc-${env_id}.key"
atc_cert_file="${key_dir}/atc-${env_id}.crt"

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

ssh_keys () {
  ssh-keygen -P "" -t rsa -f ${key_dir}/tsa-${env_id} -b 4096 -C tsa@${env_id} > /dev/null
  ssh-keygen -P "" -t rsa -f ${key_dir}/windows-worker-${env_id} -b 4096 -C windows@${env_id} > /dev/null
  ssh-keygen -P "" -t rsa -f ${key_dir}/linux-worker-${env_id} -b 4096 -C linux@${env_id} > /dev/null
}

stemcells () {
  bosh -e "${env_id}" upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
  bosh -e "${env_id}" upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-windows2012R2-go_agent?v=${windows_stemcell_version} --sha1 ${windows_stemcell_checksum}
}

releases () {
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/concourse/concourse?v=${concourse_version} --sha1 ${concourse_checksum}
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v=${garden_version} --sha1 ${garden_checksum}
  bosh -e "${env_id}" upload-release https://bosh.io/d/github.com/pivotal-cf-experimental/concourse-windows-worker-release?v=${windows_worker_version} --sha1 ${windows_worker_checksum}
  clone_windows_utilities_release
  pushd ${workdir}/windows-utilities-release
    bosh -n create-release && bosh -n -e ${env_id} upload-release
  popd
}

safe_auth () {
  safe_auth_bootstrap
}

vars () {
  atc_vault_token=`jq --raw-output '.auth.client_token' ${key_dir}/atc-${env_id}-token.json`
  vault_cert_file=${key_dir}/vault-${env_id}.crt
  concourse_password=`safe get secret/bootstrap/concourse/admin:value`
  cat <<VAR_ARGUMENTS
    --var concourse-url="${concourse_url}" --var concourse-user=${concourse_user} --var concourse-password=${concourse_password} \
    --var concourse-web-static-ip=${concourse_web_static_ip} --var atc-vault-token=${atc_vault_token} \
    --var-file atc-cert-file=${atc_cert_file} --var-file atc-key-file=${atc_key_file} --var-file vault-cert-file=${vault_cert_file} \
    --var-file tsa-private-key=${key_dir}/tsa-${env_id} --var-file tsa-public-key=${key_dir}/tsa-${env_id}.pub \
    --var-file linux-worker-private-key=${key_dir}/linux-worker-${env_id} --var-file linux-worker-public-key=${key_dir}/linux-worker-${env_id}.pub \
    --var-file windows-worker-private-key=${key_dir}/windows-worker-${env_id} --var-file windows-worker-public-key=${key_dir}/windows-worker-${env_id}.pub
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

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-concourse-windows" --allow="tcp:${rdp_port}" --source-tags="${env_id}-bosh-open" --target-tags="concourse-windows" --network="${env_id}-network "
}

lbs () {
  bbl create-lbs --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" --type concourse --key ${lb_key_file} --cert ${lb_cert_file}
}

clone_windows_utilities_release () {
  local working_directory="${workdir}/windows-utilities-release"
  if [ ! -d ${working_directory} ] ; then
    git clone ${windows_utilities_release_repository} ${working_directory}
  else
    pushd ${working_directory}
    git pull ${windows_utilities_release_repository}
    popd
  fi
}

update_runtime_config () {
  bosh -e ${env_id} runtime-config > ${workdir}/prior_runtime_config.yml
  current_config=`cat ${workdir}/prior_runtime_config.yml`
  safe_auth_bootstrap
  safe set secret/bootstrap/concourse/windows value=`windows_passphrase`
  windows_admin_password=`safe get secret/bootstrap/concourse/windows:value`
  if [[ $? -ne 0 || "${current_config}" == "null" ]] ; then
    bosh interpolate --var windows-utilities-version=${windows_utilities_version} --var windows-admin-password=${windows_admin_password} ${etc_dir}/windows-runtime-config.yml |
      bosh -n -e ${env_id} update-runtime-config -
  else
    bosh -e ${env_id} runtime-config |
      bosh interpolate -o ${etc_dir}/add-windows-utilities.yml --var windows-utilities-version=${windows_utilities_version} --var windows-admin-password=${windows_admin_password} - |
      bosh -n -e ${env_id} update-runtime-config -
  fi
}

windows_passphrase () {
  first=`generate_passphrase 1 | sed -e s/e/3/g | sed -e s/a/4/g | sed -e s/o/0/g | sed -e s/i/1/g | sed -e s/u/9/g`
  second=`generate_passphrase 1 | tr '[:lower:]' '[:upper:]'`
  third=`generate_passphrase 1 | sed -e s/e/3/g | sed -e s/a/4/g | sed -e s/o/0/g | sed -e s/i/1/g | sed -e s/u/9/g`
  fourth=`generate_passphrase 1 | tr '[:lower:]' '[:upper:]'`

  echo "$first-[$second]*$third^{$fourth}"
}

dns() {
  echo "Setting up DNS..."

  local transaction_file="${workdir}/dns-transaction-${dns_zone}.xml"

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
  fly --target ${env_id} login --team-name main --ca-cert ${key_dir}/atc-${env_id}.crt --concourse-url=${concourse_url} --username=${concourse_user} --password=${concourse_password}
}

url () {
  echo ${concourse_url}
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

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      certificates )
        ssl_certificates
        ;;
      keys )
        ssh_keys
        ;;
      security )
        ssl_certificates
        ssh_keys
        ;;
      stemcell | stemcells)
        stemcells
        ;;
      release | releases)
        releases
        ;;
      deploy )
        deploy
        ;;
      firewall )
        firewall
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
      runtime-config )
        update_runtime_config
        ;;
      interpolate )
        interpolate
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
stemcells
releases
lbs
update_runtime_config
deploy
firewall
dns
login
