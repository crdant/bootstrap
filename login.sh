#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

echo "Configuring BOSH client for the new director..."
eval "$(bbl print-env --gcp-service-account-key "${key_file}")"
bosh_client=`bbl director-username`
bosh_client_secret=`bbl director-password`
bosh_ca_cert=`bbl director-ca-cert --gcp-service-account-key "${key_file}"`
bosh_director_address=`bbl director-address --gcp-service-account-key "${key_file}"`
bosh alias-env --environment="${bosh_director_address}" --ca-cert="${bosh_ca_cert}" "${ENVIRONMENT_NAME}"

echo "Logging into the new director..."
bosh log-in -e "${ENVIRONMENT_NAME}" --client="${bosh_client}" --client-secret="${bosh_client_secret}"
