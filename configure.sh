#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id`

vault_port=8200
vault_addr=https://localhost:${vault_port}
vault_cert_file=${key_dir}/vault-${env_id}.crt

set -e

auth () {
  vault auth  --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r .root_token ${key_dir}/vault_secrets.json`
}

policies () {
  vault policy-write --address ${vault_addr} --ca-cert=${vault_cert_file} conrad ${etc_dir}/conrad.hcl
  vault policy-write --address ${vault_addr} --ca-cert=${vault_cert_file} concourse ${etc_dir}/concourse.hcl
}

tokens () {
  vault token-create --address ${vault_addr} --ca-cert=${vault_cert_file} --policy conrad > "${key_dir}/conrad-${subdomain_token}.token"
  vault token-create --address ${vault_addr} --ca-cert=${vault_cert_file} --policy concourse > "${key_dir}/atc-${subdomain_token}.token"
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
