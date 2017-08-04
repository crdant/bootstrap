#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

echo "Destroying the BOSH director..."
bbl down --no-confirm

echo "Deleting service accounts..."
KEYID=`jq --raw-output '.private_key_id' "${KEYFILE}" `
gcloud iam service-accounts --project "${PROJECT}" keys delete "${KEYID}" --iam-account "${SERVICE_ACCOUNT}" --no-user-output-enabled
gcloud iam service-accounts --project "${PROJECT}" delete "${SERVICE_ACCOUNT}"

rm -rf ${KEYDIR}/*
rm -rf ${WORKDIR}/*
rm bbl-state.json
