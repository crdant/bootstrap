#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. ${workdir}/bbl-env.sh

env_id=`bbl env-id`
stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

vault_version=0.6.2
vault_checksum=36fd3294f756372ff9fbbd6dfac11fe6030d02f9
vault_static_ip=10.0.31.195
vault_port=8200
vault_addr=https://localhost:${vault_port}

export vault_cert_file=${key_dir}/vault-${env_id}.crt
export vault_key_file=${key_dir}/vault-${env_id}.key

ssl_certificates () {
  echo "Creating SSL certificate..."

  common_name="vault.${subdomain}"
  country="US"
  state="MA"
  city="Cambridge"
  organization="${domain}"
  org_unit="Vault"
  email="${account}"
  alt_names="IP:${vault_static_ip},DNS:localhost,IP:127.0.0.1"
  subject="/C=${country}/ST=${state}/L=${city}/O=${organization}/OU=${org_unit}/CN=${common_name}/emailAddress=${email}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${vault_key_file}" -out "${vault_cert_file}" -subj "${subject}" -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=${alt_names}\n"))  > /dev/null
}

stemcell () {
  bosh -n -e ${env_id} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

releases () {
  bosh -n -e ${env_id} upload-release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease?v=${vault_version} --sha1 ${vault_checksum}
}

prepare_manifest () {
  local manifest=${workdir}/vault.yml
  vault_static_ip=${vault_static_ip} spruce merge ${manifest_dir}/vault.yml > ${manifest}
}

deploy () {
  local manifest=${workdir}/vault.yml
  bosh -n -e ${env_id} -d vault deploy ${manifest}
}

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-vault" --allow="tcp:${vault_port}" --source-tags="${env_id}-bosh-open" --target-tags="${env_id}-internal" --network="${env_id}-network "
}

tunnel () {
  ssh -fnNT -L 8200:${vault_static_ip}:8200 jumpbox@${jumpbox} -i $BOSH_GW_PRIVATE_KEY
}

unseal() {
  # unseal the vault
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[0]' ${key_dir}/vault_secrets.json`
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[1]' ${key_dir}/vault_secrets.json`
  vault unseal --address ${vault_addr} --ca-cert=${vault_cert_file} `jq -r '.keys_base64[2]' ${key_dir}/vault_secrets.json`
}

init () {
  # initialize the vault using the API directly to parse the JSON
  initialization=`cat ${etc_dir}/vault_init.json`
  curl -qs --cacert ${vault_cert_file} -X PUT "${vault_addr}/v1/sys/init" -H "Accept: application/json" -H "Content-Type: application/json" -d "${initialization}" | jq '.' >${key_dir}/vault_secrets.json
  unseal
}


teardown () {
  bosh -n -e ${env_id} -d vault delete-deployment
  gcloud --project "${project}" compute firewall-rules delete "${env_id}-vault"
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
