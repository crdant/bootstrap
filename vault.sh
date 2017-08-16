#!/usr/bin/env bash
STEMCELL_VERSION=3431.10
VAULT_VERSION=3.3.4
VAULT_STATIC_IP=10.0.31.195

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

stemcell () {
  stemcell_file=${WORKDIR}/light-bosh-stemcell-${STEMCELL_VERSION}-google-kvm-ubuntu-trusty-go_agent.tgz
  wget -O $stemcell_file https://s3.amazonaws.com/bosh-gce-light-stemcells/light-bosh-stemcell-${STEMCELL_VERSION}-google-kvm-ubuntu-trusty-go_agent.tgz
  bosh -e ${ENVIRONMENT_NAME} upload-stemcell $stemcell_file
}

releases () {
  vault_release="https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease"
  bosh -e ${ENVIRONMENT_NAME} upload-release ${vault_release}
}

prepare_manifest () {
  manifest=${WORKDIR}/vault.yml
  spruce merge ${MANIFEST_DIR}/vault.yml > $manifest
  VAULT_STATIC_IP=`spruce json $manifest | jq -r '.instance_groups[].networks[].static_ips'`
}

deploy () {
  bosh -n -e ${ENVIRONMENT_NAME} -d vault deploy ${manifest}
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

stemcell
releases
prepare_manifest
deploy
init
