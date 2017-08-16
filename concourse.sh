#!/usr/bin/env bash
STEMCELL_VERSION=3431.13
STEMCELL_CHECKSUM=8ae6d01f01f627e70e50f18177927652a99a4585
CONCOURSE_VERSION=3.4.0
CONCOURSE_CHECKSUM=e262b0fb209df6134ea15917e2b9b8bfb8d0d0d1
GARDEN_RUNC_VERSION=1.6.0
GARDEN_RUNC_CHECKSUM=58fbc64aff303e6d76899441241dd5dacef50cb7


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
  bosh -e ${ENVIRONMENT_NAME} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION} --sha1 ${STEMCELL_CHECKSUM}
}

releases () {
  concourse_file=${WORKDIR}/concourse-${CONCOURSE_VERSION}.tgz
  garden_runc_file=${WORKDIR}/garden-runc-${GARDEN_RUNC_VERSION}.tgz

  bosh -e ${ENVIRONMENT_NAME} upload-release https://bosh.io/d/github.com/concourse/concourse?v=${CONCOURSE_VERSION} --sha1 ${CONCOURSE_CHECKSUM}
  bosh -e ${ENVIRONMENT_NAME} upload-release https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v=${GARDEN_RUNC_VERSION} --sha1 ${GARDEN_RUNC_CHECKSUM}
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


if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      certificates )
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
      init )
        init
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
    exit
  done
fi

ssl_certificates
stemcell
releases
prepare_manifest
deploy
init
