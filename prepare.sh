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
  echo "Configuring service accounts..."
  gcloud iam service-accounts --project "${project}" create "${service_account_name}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" keys create "${key_file}"  --iam-account "${service_account}" --no-user-output-enabled
  gcloud projects add-iam-policy-binding "${pbbl roject}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
}

director() {
  echo "Creating the $env_id BOSH director..."
  bbl up --iaas gcp --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" --gcp-zone "${availability_zone_1}" --gcp-region "${region}" --credhub
  env_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
  firewall
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
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
  bbl_env=`bbl print-env --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
  echo "${bbl_env}" | sed '/ssh/ d' > ${workdir}/bbl-env.sh
  chmod 755 ${workdir}/bbl-env.sh
  eval "$bbl_env"
  # store the ssh key for easy use
  if [ -f ${key_dir}/id_jumpbox_${env_id}.pem ] ; then
    chmod 600 ${key_dir}/id_jumpbox_${env_id}.pem
  fi
  bbl ssh-key --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" > ${key_dir}/id_jumpbox_${env_id}.pem
  chmod 400 ${key_dir}/id_jumpbox_${env_id}.pem

  bosh_ca_cert=`bbl director-ca-cert --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
  bosh_director_address=`bbl director-address --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
  bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" `bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
}

login() {
  echo "Logging into the $env_id director..."
  . "${workdir}/bbl-env.sh"
  bosh log-in -e `bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"` --client="${BOSH_CLIENT}" --client-secret="${BOSH_CLIENT_SECRET}"
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      accounts )
        service_accounts
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
director
dns
client
login
