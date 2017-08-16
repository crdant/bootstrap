#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
set -e

auth () {
  vault auth `jq -r .root_token ${KEYDIR}/vault_secrets.json`
}

policies () {
  vault policy-write conrad ${ETCDIR}/conrad.hcl
  vault policy-write concourse ${ETCDIR}/concourse.hcl
}

tokens () {
  vault token-create --policy conrad > "${KEYDIR}/conrad-${SUBDOMAIN_TOKEN}.token"
  vault token-create --policy concourse > "${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.token"
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
