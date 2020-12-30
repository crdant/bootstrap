#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

if [ ! -d ${workdir} ] ; then
  mkdir -p ${workdir}
fi

if [ ! -d ${key_dir} ] ; then
  mkdir -p ${key_dir}
fi

service_accounts() {
  if [ "${iaas}" == "gcp "] ; then
    echo "Configuring service accounts..."
    gcloud iam service-accounts --project "${project}" create "${service_account_name}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
    gcloud iam service-accounts --project "${project}" keys create "${key_file}"  --iam-account "${service_account}" --no-user-output-enabled
    gcloud projects add-iam-policy-binding "${project}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
  elif [ "${iaas}" == "azure" ] ; then
    local client_id="$(az ad app create --display-name "${env_id} BOSH Director" --password "$(generate_passphrase 4)" --homepage "http://bbl-${env_id}-director" --identifier-uris "http://bbl-${env_id}-director" | jq -r .appId)"
  fi
}

ca () {
  certstrap --depot-path "${ca_dir}" init --common-name "${ca_name}"
}

director() {
  echo "Creating the $env_id BOSH director..."
  bbl up --iaas ${iaas} $iaas_auth_flag $iaas_location_flag --gcp-region "${region}"
  env_id=`bbl env-id --gcp-service-account-key "${key_file}"`
  firewall
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id --gcp-service-account-key "${key_file}"`
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

client() {
  echo "Configuring BOSH client for the $env_id director..."
  # can't reuse bbl print-env without redoing the tunnel (with new port), so be aware of that by saving the variable setting
  bbl_env=`bbl print-env --gcp-service-account-key "${key_file}"`
  echo "${bbl_env}" | sed '/ssh/ d' > ${workdir}/bbl-env.sh
  chmod 755 ${workdir}/bbl-env.sh
  eval "$bbl_env"
  # store the ssh key for easy use
  if [ -f ${key_dir}/id_jumpbox_${env_id}.pem ] ; then
    chmod 600 ${key_dir}/id_jumpbox_${env_id}.pem
  fi
  bbl ssh-key $iaas_auth_flag> ${key_dir}/id_jumpbox_${env_id}.pem
  chmod 400 ${key_dir}/id_jumpbox_${env_id}.pem

  bosh_ca_cert=`bbl director-ca-cert --gcp-service-account-key "${key_file}"`
  bosh_director_address=`bbl director-address --gcp-service-account-key "${key_file}"`
  bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" `bbl env-id --gcp-service-account-key "${key_file}"`
}

login() {
  echo "Logging into the $env_id director..."
  . "${workdir}/bbl-env.sh"
  bosh log-in -e `bbl env-id --gcp-service-account-key "${key_file}"` --client="${BOSH_CLIENT}" --client-secret="${BOSH_CLIENT_SECRET}"
}

trust () {
  security add-trusted-cert -d -p ssl -k ${HOME}/Library/Keychains/login.keychain ${ca_cert_file}
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      accounts )
        service_accounts
        ;;
      ca )
        ca
        ;;
      dns )
        dns
        ;;
      director )
        director
        ;;
      firewall )
        firewall
        ;;
      client )
        client
        ;;
      login )
        login
        ;;
      trust )
        trust
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
    exit
  done
fi

service_accounts
ca
director
dns
client
login
trust
