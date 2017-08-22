#!/usr/bin/env bash

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

director() {
  echo "Destroying the BOSH director..."
  bbl down --no-confirm
}

service_accounts () {
  echo "Deleting service accounts..."
  KEYID=`jq --raw-output '.private_key_id' "${key_file}" `
  gcloud projects remove-iam-policy-binding "${project}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" keys delete "${KEYID}" --iam-account "${service_account}" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" delete "${service_account}" --no-user-output-enabled
}

cleanup() {
  chmod 600 ${key_dir}/id_jumpbox_${env_id}.pem
  rm -rf ${key_dir}/*
  rm -rf ${workdir}/*
  rm bbl-state.json
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      director )
        director
        ;;
      accounts )
        service_accounts
        ;;
      cleanup )
        cleanup
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

director
service_accounts
cleanup
