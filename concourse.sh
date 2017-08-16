#!/usr/bin/env bash
STEMCELL_VERSION=3431.10
CONCOURSE_VERSION=3.3.4
GARDEN_RUNC_VERSION=1.6.0

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

ssl_certificates () {
  LB_KEY_FILE="${KEYDIR}/web-${SUBDOMAIN_TOKEN}.key"
  LB_CERT_FILE="${KEYDIR}/web-${SUBDOMAIN_TOKEN}.crt"

  export ATC_KEY_FILE="${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.key"
  export ATC_CERT_FILE="${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.crt"
  export ATC_VAULT_TOKEN=`cat keys/atc-gcp-crdant-io.token | grep "token " | awk '{ print $2; }'`

  echo "Creating SSL certificate for load balancers..."

  COMMON_NAME="*.${SUBDOMAIN}"
  COUNTRY="US"
  STATE="MA"
  CITY="Cambridge"
  ORGANIZATION="${DOMAIN}"
  ORG_UNIT="Continuous Delivery"
  EMAIL="${ACCOUNT}"
  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${LB_KEY_FILE}" -out "${LB_CERT_FILE}" -subj "${SUBJECT}" > /dev/null

  echo "SSL certificate for load balanacers created and stored at ${KEYDIR}/${SUBDOMAIN_TOKEN}.crt, private key stored at ${KEYDIR}/${SUBDOMAIN_TOKEN}.key."

  echo "Creating SSL certificate for ATC..."

  COMMON_NAME="*.${SUBDOMAIN}"
  COUNTRY="US"
  STATE="MA"
  CITY="Cambridge"
  ORGANIZATION="${DOMAIN}"
  ORG_UNIT="Continuous Delivery"
  EMAIL="${ACCOUNT}"
  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${ATC_KEY_FILE}" -out "${ATC_CERT_FILE}" -subj "${SUBJECT}" > /dev/null
}

stemcell () {
  stemcell_file=${WORKDIR}/light-bosh-stemcell-${STEMCELL_VERSION}-google-kvm-ubuntu-trusty-go_agent.tgz
  wget -O $stemcell_file https://s3.amazonaws.com/bosh-gce-light-stemcells/light-bosh-stemcell-${STEMCELL_VERSION}-google-kvm-ubuntu-trusty-go_agent.tgz
  bosh -e ${ENVIRONMENT_NAME} upload-stemcell $stemcell_file
}

releases () {
  concourse_file=${WORKDIR}/concourse-${CONCOURSE_VERSION}.tgz
  garden_runc_file=${WORKDIR}/garden-runc-${GARDEN_RUNC_VERSION}.tgz

  wget -O $concourse_file https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/concourse-${CONCOURSE_VERSION}.tgz
  bosh -e ${ENVIRONMENT_NAME} upload-release $concourse_file
  wget -O $garden_runc_file https://github.com/concourse/concourse/releases/download/v${CONCOURSE_VERSION}/garden-runc-${GARDEN_RUNC_VERSION}.tgz
  bosh -e ${ENVIRONMENT_NAME} upload-release $garden_runc_file
}

prepare_manifest () {
  manifest=${WORKDIR}/concourse.yml
  spruce merge --prune tls ${MANIFEST_DIR}/concourse.yml > $manifest
}

deploy () {
  bbl create-lbs --type concourse
  bosh -n -e ${ENVIRONMENT_NAME} -d concourse deploy ${manifest}
}

init () {
  vault
}

ssl_certificates
stemcell
releases
prepare_manifest
deploy
init
