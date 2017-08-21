#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

service_accounts() {
  echo "Configuring service accounts..."
  gcloud iam service-accounts --project "${PROJECT}" create "${SERVICE_ACCOUNT_NAME}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
  gcloud iam service-accounts --project "${PROJECT}" keys create "${KEYFILE}"  --iam-account "${SERVICE_ACCOUNT}" --no-user-output-enabled
  gcloud projects add-iam-policy-binding "${PROJECT}" --member "serviceAccount:${SERVICE_ACCOUNT}" --role "roles/editor" --no-user-output-enabled
}

director() {
  echo "Creating the BOSH director..."
  bbl up --iaas gcp --gcp-service-account-key "${KEYFILE}" --gcp-project-id "${PROJECT}" --gcp-zone "${AVAILABILITY_ZONE}" --gcp-region "${REGION}" --credhub
  firewall
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  env_id=`bbl env-id`
  gcloud --project "${PROJECT}" compute firewall-rules update ${env_id}-bosh-open --target-tags=${env_id}-bosh-director,${env_id}-internal
}

client() {
  echo "Configuring BOSH client for the new director..."
  # can't reuse bbl print-env without redoing the tunnel (with new port), so be aware of that by saving the variable setting
  bbl_env=`bbl print-env`
  echo "${bbl_env}" | sed '/ssh/ d' > ${WORKDIR}/bbl-env.sh
  chmod 755 ${WORKDIR}/bbl-env.sh
  eval "$bbl_env"
  # store the ssh key for easy use
  chmod 600 ${KEYDIR}/id_jumpbox_${SUBDOMAIN_TOKEN}.pem
  bbl ssh-key > ${KEYDIR}/id_jumpbox_${SUBDOMAIN_TOKEN}.pem
  chmod 400 ${KEYDIR}/id_jumpbox_${SUBDOMAIN_TOKEN}.pem

  bosh_ca_cert=`bbl director-ca-cert`
  bosh_director_address=`bbl director-address`
  bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" `bbl env-id`
}

login() {
  echo "Logging into the new director..."
  . "${WORKDIR}/bbl-env.sh"
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
