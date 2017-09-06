#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"

stemcell_version=3431.13
stemcell_checksum=8ae6d01f01f627e70e50f18177927652a99a4585

ldap_release_repository=https://github.com/cloudfoundry-community/openldap-boshrelease.git
ldap_static_ip=10.0.47.195
ldap_cert_file="${key_dir}/ldap-${env_id}.crt"
ldap_key_file="${key_dir}/ldap-${env_id}.key"

# ldap_static_ip=10.244.0.2
ldap_port=636

ssl_certificates () {
  echo "Creating SSL certificate..."

  common_name="ldap.${subdomain}"
  country="US"
  state="MA"
  city="Cambridge"
  organization="${domain}"
  org_unit="LDAP"
  email="${account}"
  alt_names="IP:${ldap_static_ip},DNS:localhost,IP:127.0.0.1"
  subject="/C=${country}/ST=${state}/L=${city}/O=${organization}/OU=${org_unit}/CN=${common_name}/emailAddress=${email}"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 -keyout "${ldap_key_file}" -out "${ldap_cert_file}" -subj "${subject}" -reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=${alt_names}\n"))  > /dev/null
}

stemcell () {
  bosh -n -e ${env_id} upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=${stemcell_version} --sha1 ${stemcell_checksum}
}

clone_release () {
  if [ ! -d ${workdir}/pcf_pipelines ] ; then
    git clone ${ldap_release_repository} ${workdir}/openldap-boshrelease
  else
    pushd ${workdir}/pcf_pipelines
    git pull ${ldap_release_repository}
    popd
  fi
}

releases () {
  clone_release
  pushd ${workdir}/openldap-boshrelease
    bosh -n create-release && bosh -n -e ${env_id} upload-release
  popd
}


safe_auth () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}

vars () {
  safe_auth

  ldap_olc_suffix='cn=config,dc=crdant,dc=io'
  ldap_olc_root_dn="cn=admin,${ldap_olc_suffix}"
  ldap_olc_root_password=`safe get secret/bootstrap/ldap/admin:value`

  if [ -z "${ldap_olc_root_password}" ] ; then
    safe set secret/bootstrap/ldap/admin value=`generate_passphrase 4`
    ldap_olc_root_password=`safe get secret/bootstrap/ldap/admin:value`
  fi
}

interpolate () {
  local manifest=${manifest_dir}/ldap.yml

  vars
  bosh interpolate ${manifest} \
    --var olc-suffix="${ldap_olc_suffix}" --var olc-root-dn="${ldap_olc_root_dn}" --var olc-root-password="${ldap_olc_root_password}" --var ldap-static-ip="${ldap_static_ip}" \
    --var-file ldap-cert="${ldap_cert_file}" --var-file ldap-key="${ldap_key_file}"
}

deploy () {
  local manifest=${manifest_dir}/ldap.yml
  safe_auth
  safe set secret/bootstrap/ldap/admin value=`generate_passphrase 4`

  vars

  bosh -n -e ${env_id} -d openldap deploy ${manifest} \
    --var olc-suffix="${ldap_olc_suffix}" --var olc-root-dn="${ldap_olc_root_dn}" --var olc-root-password="${ldap_olc_root_password}" --var ldap-static-ip="${ldap_static_ip}" \
    --var-file ldap-cert="${key_dir}/ldap-${env_id}.crt" --var-file ldap-key="${key_dir}/ldap-${env_id}.key"
}

firewall() {
  gcloud --project "${project}" compute firewall-rules create "${env_id}-ldap" --allow="tcp:${ldap_port}" --source-tags="${env_id}-bosh-open" --target-tags="${env_id}-internal" --network="${env_id}-network "
}

tunnel () {
  ssh -fnNT -L 6${ldap_port}:${ldap_static_ip}:${ldap_port} jumpbox@${jumpbox} -i $BOSH_GW_PRIVATE_KEY
}

teardown () {
  bosh -n -e ${env_id} -d ldap delete-deployment
  gcloud --project "${project}" compute firewall-rules delete "${env_id}-ldap"
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
        releases
        ;;
      interpolate )
        interpolate
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
deploy
firewall
tunnel