#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`

vault_port=8200
vault_addr=https://localhost:${vault_port}
vault_cert_file=${key_dir}/vault-${env_id}.crt

set -e

auth () {
  vault auth --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r .root_token ${key_dir}/vault_secrets.json`
}

mount() {
  vault mount --address ${vault_addr} --ca-cert=${vault_cert_file} --path=/concourse generic
}

policies () {
  vault policy-write --address ${vault_addr} --ca-cert=${vault_cert_file} conrad ${etc_dir}/conrad.hcl
  vault policy-write --address ${vault_addr} --ca-cert=${vault_cert_file} concourse ${etc_dir}/concourse.hcl
  vault policy-write --address ${vault_addr} --ca-cert=${vault_cert_file} alger ${etc_dir}/alger.hcl
}

tokens () {
  vault token-create --address ${vault_addr} --ca-cert=${vault_cert_file} --format json --policy conrad > "${key_dir}/conrad-${env_id}-token.json"
  vault token-create --address ${vault_addr} --ca-cert=${vault_cert_file} --format json --policy concourse > "${key_dir}/atc-${env_id}-token.json"
  vault token-create --address ${vault_addr} --ca-cert=${vault_cert_file} --format json --policy alger > "${key_dir}/bootstrap-${env_id}-token.json"
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
      mount )
        mount
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
mount
policies
tokens
