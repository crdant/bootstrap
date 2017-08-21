#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${WORKDIR}/bbl-env.sh

env_id=`bbl env-id`

VAULT_PORT=8200
VAULT_ADDR=https://localhost:${VAULT_PORT}
VAULT_CERT_FILE=${KEYDIR}/vault-${env_id}.crt

set -e

auth () {
  vault auth  --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} `jq -r .root_token ${KEYDIR}/vault_secrets.json`
}

policies () {
  vault policy-write --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} conrad ${ETCDIR}/conrad.hcl
  vault policy-write --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} concourse ${ETCDIR}/concourse.hcl
}

tokens () {
  vault token-create --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} --policy conrad > "${KEYDIR}/conrad-${SUBDOMAIN_TOKEN}.token"
  vault token-create --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} --policy concourse > "${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.token"
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
