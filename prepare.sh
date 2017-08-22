#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

service_accounts() {
  echo "Configuring service accounts..."
  gcloud iam service-accounts --project "${project}" create "${service_account_name}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" keys create "${key_file}"  --iam-account "${service_account}" --no-user-output-enabled
  gcloud projects add-iam-policy-binding "${project}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
}

director() {
  echo "Creating the BOSH director..."
  bbl up --iaas gcp --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" --gcp-zone "${availability_zone}" --gcp-region "${region}" --credhub
  firewall
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id`
  gcloud --project "${project}" compute firewall-rules update ${env_id}-bosh-open --target-tags=${env_id}-bosh-director,${env_id}-internal
}

client() {
  echo "Configuring BOSH client for the new director..."
  # can't reuse bbl print-env without redoing the tunnel (with new port), so be aware of that by saving the variable setting
  bbl_env=`bbl print-env`
  echo "${bbl_env}" | sed '/ssh/ d' > ${workdir}/bbl-env.sh
  chmod 755 ${workdir}/bbl-env.sh
  eval "$bbl_env"
  # store the ssh key for easy use
  chmod 600 ${key_dir}/id_jumpbox_${env_id}.pem
  bbl ssh-key > ${key_dir}/id_jumpbox_${env_id}.pem
  chmod 400 ${key_dir}/id_jumpbox_${env_id}.pem

  bosh_ca_cert=`bbl director-ca-cert`
  bosh_director_address=`bbl director-address`
  bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" `bbl env-id`
}

login() {
  echo "Logging into the new director..."
  . "${workdir}/bbl-env.sh"
  bosh log-in -e `bbl env-id` --client="${BOSH_CLIENT}" --client-secret="${BOSH_CLIENT_SECRET}"
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      accounts )
        service_accounts
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
client
login
