#!/usr/bin/env bash
STEMCELL_VERSION=3431.13
STEMCELL_CHECKSUM=8ae6d01f01f627e70e50f18177927652a99a4585
VAULT_VERSION=0.6.2
VAULT_CHECKSUM=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
VAULT_STATIC_IP=10.0.31.195

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

stemcell () {
  bosh -e ${ENVIRONMENT_NAME} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION} --sha1 ${STEMCELL_CHECKSUM}
}

releases () {
  bosh -e ${ENVIRONMENT_NAME} upload-release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease?v=${VAULT_VERSION} --sha1 ${VAULT_CHECKSUM}
}

prepare_manifest () {
  manifest=${WORKDIR}/vault.yml
  spruce merge ${MANIFEST_DIR}/vault.yml > $manifest
  VAULT_STATIC_IP=`spruce json $manifest | jq -r '.instance_groups[].networks[].static_ips'`
}

deploy () {
  bosh -n -e ${ENVIRONMENT_NAME} -d vault deploy ${manifest}
}

tunnel () {
  ssh -fnNT -L 8200:${VAULT_STATIC_IP}:8200 jumpbox@${JUMPBOX} -i $BOSH_GW_PRIVATE_KEY
  VAULT_ADDR=http://localhost:8200
}

init () {
  # initialize the vault using the API directly to parse the JSON
  initialization=`cat ${ETCDIR}/vault_init.json`
  curl -q -X PUT "${VAULT_ADDR}/v1/sys/init" -H "Accept: application/json" -H "Content-Type: application/json" -d "${initialization}" | jq '.' >${KEYDIR}/vault_secrets.json

  # unseal the vault
  vault unseal `jq -r '.keys_base64[0]' ${KEYDIR}/vault_secrets.json`
  vault unseal `jq -r '.keys_base64[1]' ${KEYDIR}/vault_secrets.json`
  vault unseal `jq -r '.keys_base64[2]' ${KEYDIR}/vault_secrets.json`
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      stemcell )
        stemcell
        ;;
      release )
        release
        ;;
      manifest )
          prepare_manifest
        ;;
      deploy )
        deploy
        ;;
      tunnel )
        tunnel
        ;;
      init )
        init
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

stemcell
releases
prepare_manifest
deploy
tunnel
init
