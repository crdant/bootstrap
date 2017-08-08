#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

echo "Configuring service accounts..."
gcloud iam service-accounts --project "${PROJECT}" create "${SERVICE_ACCOUNT_NAME}" --display-name "BOSH Boot Loader (bbl)" --no-user-output-enabled
gcloud iam service-accounts --project "${PROJECT}" keys create "${KEYFILE}"  --iam-account "${SERVICE_ACCOUNT}" --no-user-output-enabled

gcloud projects add-iam-policy-binding "${PROJECT}" --member "serviceAccount:${SERVICE_ACCOUNT}" --role "roles/editor" --no-user-output-enabled

echo "Creating the BOSH director..."
bbl up --iaas gcp --gcp-service-account-key "${KEYFILE}" --gcp-project-id "${PROJECT}" --gcp-zone "${AVAILABILITY_ZONE}" --gcp-region "${REGION}" --jumpbox

echo "Configuring BOSH client for the new director..."
bosh_client=`bbl director-username`
bosh_client_secret=`bbl director-password`
bosh_ca_cert=`bbl director-ca-cert`
bosh_director_address=`bbl director-address`
bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" "${ENVIRONMENT_NAME}"

echo "Logging into the new director..."
bosh log-in -e "${ENVIRONMENT_NAME}" --client="${bosh_client}" --client-secret="${bosh_client_secret}"
