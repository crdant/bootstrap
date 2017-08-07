#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

echo "Destroying the BOSH director..."
bbl down --no-confirm

echo "Deleting service accounts..."
KEYID=`jq --raw-output '.private_key_id' "${KEYFILE}" `
gcloud projects remove-iam-policy-binding "${PROJECT}" --member "serviceAccount:${SERVICE_ACCOUNT}" --role "roles/editor" --no-user-output-enabled
gcloud iam service-accounts --project "${PROJECT}" keys delete "${KEYID}" --iam-account "${SERVICE_ACCOUNT}" --no-user-output-enabled
gcloud iam service-accounts --project "${PROJECT}" delete "${SERVICE_ACCOUNT}" --no-user-output-enabled

chmod 400 ${KEYDIR}/id_jumpbox_${SUBDOMAIN_TOKEN}.pem
rm -rf ${KEYDIR}/*
rm -rf ${WORKDIR}/*
rm bbl-state.json
