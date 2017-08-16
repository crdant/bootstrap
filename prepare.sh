#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

serivce_accounts() {
  echo "Configuring service accounts..."
  gcloud iam service-accounts --project "${PROJECT}" create "${SERVICE_ACCOUNT_NAME}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
  gcloud iam service-accounts --project "${PROJECT}" keys create "${KEYFILE}"  --iam-account "${SERVICE_ACCOUNT}" --no-user-output-enabled
  gcloud projects add-iam-policy-binding "${PROJECT}" --member "serviceAccount:${SERVICE_ACCOUNT}" --role "roles/editor" --no-user-output-enabled
}

director() {
  echo "Creating the BOSH director..."
  set +e
  bbl up --iaas gcp --gcp-service-account-key "${KEYFILE}" --gcp-project-id "${PROJECT}" --gcp-zone "${AVAILABILITY_ZONE}" --gcp-region "${REGION}" --jumpbox
  set -e
}

client() {
  echo "Configuring BOSH client for the new director..."
  eval "$(bbl print-env)"
  bosh_client=`bbl director-username`
  bosh_client_secret=`bbl director-password`
  bosh_ca_cert=`bbl director-ca-cert`
  bosh_director_address=`bbl director-address`
  bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" "${ENVIRONMENT_NAME}"
}

login() {
  echo "Logging into the new director..."
  bosh log-in -e "${ENVIRONMENT_NAME}" --client="${bosh_client}" --client-secret="${bosh_client_secret}"
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

service-accounts
director
client
login
