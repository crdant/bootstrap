#!/usr/bin/env bash
STEMCELL_VERSION=3431.10
VAULT_VERSION=3.3.4

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

deploy () {
  bosh -e ${ENVIRONMENT_NAME} -d vault deploy ${MANIFEST_DIR}/vault.yml
}

stemcell
releases
deploy
