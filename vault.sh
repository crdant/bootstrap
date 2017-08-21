#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${WORKDIR}/bbl-env.sh

env_id=`bbl env-id`
STEMCELL_VERSION=3431.13
STEMCELL_CHECKSUM=8ae6d01f01f627e70e50f18177927652a99a4585

VAULT_VERSION=0.6.2
VAULT_CHECKSUM=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
VAULT_STATIC_IP=10.0.31.195
VAULT_PORT=8200
VAULT_ADDR=https://localhost:${VAULT_PORT}

export VAULT_CERT_FILE=${KEYDIR}/vault-${env_id}.crt
export VAULT_KEY_FILE=${KEYDIR}/vault-${env_id}.key

ssl_certificates () {
  echo "Creating SSL certificate..."

  COMMON_NAME="vault.${SUBDOMAIN}"
  COUNTRY="US"
  STATE="MA"
  CITY="Cambridge"
  ORGANIZATION="${DOMAIN}"
  ORG_UNIT="Vault"
  EMAIL="${ACCOUNT}"
  ALT_NAMES="IP:${VAULT_STATIC_IP},DNS:localhost,IP:127.0.0.1"
  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${VAULT_KEY_FILE}" -out "${VAULT_CERT_FILE}" -subj "${SUBJECT}" -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=${ALT_NAMES}\n"))  > /dev/null
}

stemcell () {
  bosh -n -e ${env_id} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION} --sha1 ${STEMCELL_CHECKSUM}
}

releases () {
  bosh -n -e ${env_id} upload-release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease?v=${VAULT_VERSION} --sha1 ${VAULT_CHECKSUM}
}

prepare_manifest () {
  local manifest=${WORKDIR}/vault.yml
  VAULT_STATIC_IP=${VAULT_STATIC_IP} spruce merge ${MANIFEST_DIR}/vault.yml > ${manifest}
}

deploy () {
  local manifest=${WORKDIR}/vault.yml
  bosh -n -e ${env_id} -d vault deploy ${manifest}
}

firewall() {
  gcloud --project "${PROJECT}" compute firewall-rules create "${env_id}-vault" --allow="tcp:${VAULT_PORT}" --source-tags="${env_id}-bosh-open" --target-tags="${env_id}-internal" --network="${env_id}-network "
}

tunnel () {
  ssh -fnNT -L 8200:${VAULT_STATIC_IP}:8200 jumpbox@${jumpbox} -i $BOSH_GW_PRIVATE_KEY
}

unseal() {
  # unseal the vault
  vault unseal --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} `jq -r '.keys_base64[0]' ${KEYDIR}/vault_secrets.json`
  vault unseal --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} `jq -r '.keys_base64[1]' ${KEYDIR}/vault_secrets.json`
  vault unseal --address ${VAULT_ADDR} --ca-cert=${VAULT_CERT_FILE} `jq -r '.keys_base64[2]' ${KEYDIR}/vault_secrets.json`
}

init () {
  # initialize the vault using the API directly to parse the JSON
  initialization=`cat ${ETCDIR}/vault_init.json`
  curl -qs --cacert ${VAULT_CERT_FILE} -X PUT "${VAULT_ADDR}/v1/sys/init" -H "Accept: application/json" -H "Content-Type: application/json" -d "${initialization}" | jq '.' >${KEYDIR}/vault_secrets.json
  unseal
}


teardown () {
  bosh -n -e ${env_id} -d vault delete-deployment
  gcloud --project "${PROJECT}" compute firewall-rules delete "${env_id}-vault"
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      certificates )
        ssl_certificates
        ;;
      security )
        ssl_certificates
        ;;
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
      firewall )
        firewall
        ;;
      tunnel )
        tunnel
        ;;
      init )
        init
        ;;
      unseal )
        unseal
        ;;
      teardown )
        teardown
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

ssl_certificates
stemcell
releases
prepare_manifest
deploy
firewall
tunnel
init
