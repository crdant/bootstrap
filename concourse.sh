#!/usr/bin/env bash
STEMCELL_VERSION=3431.10
CONCOURSE_VERSION=3.3.4
GARDEN_RUNC_VERSION=1.6.0

BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"

ssl_certificates () {
  echo "Creating SSL certificate for load balancers..."

  COMMON_NAME="*.${SUBDOMAIN}"
  COUNTRY="US"
  STATE="MA"
  CITY="Cambridge"
  ORGANIZATION="${DOMAIN}"
  ORG_UNIT="Continuous Delivery"
  EMAIL="${ACCOUNT}"
  SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${KEYDIR}/concourse.${SUBDOMAIN_TOKEN}.key" -out "${KEYDIR}/${SUBDOMAIN_TOKEN}.crt" -subj "${SUBJECT}" > /dev/null

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

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.key" -out "${KEYDIR}/atc-${SUBDOMAIN_TOKEN}.crt" -subj "${SUBJECT}" > /dev/null
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

deploy () {
  bbl create-lbs --type concourse
  bosh -e ${ENVIRONMENT_NAME} -d concourse deploy ${MANIFEST_DIR}/concourse.yml
}

ssl_certificates
stemcell
releases
deploy
