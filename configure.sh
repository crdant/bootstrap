#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id`

VAULT_PORT=8200
VAULT_ADDR=https://localhost:${VAULT_PORT}
VAULT_CERT_FILE=${key_dir}/vault-${env_id}.crt

set -e

auth () {
  vault auth  --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} `jq -r .root_token ${key_dir}/vault_secrets.json`
}

policies () {
  vault policy-write --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} conrad ${etc_dir}/conrad.hcl
  vault policy-write --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} concourse ${etc_dir}/concourse.hcl
}

tokens () {
  vault token-create --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} --policy conrad > "${key_dir}/conrad-${subdomain_token}.token"
  vault token-create --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} --policy concourse > "${key_dir}/atc-${subdomain_token}.token"
}


if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      auth )
        auth
        ;;
      policies )
        policies
        ;;
      tokens )
        tokens
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
  done
  exit
fi

auth
policies
tokens
