email=cdantonio@pivotal.io
pivnet_token=${PIVNET_TOKEN}
domain=crdant.io
iaas=gcp

domain_token=`echo ${domain} | tr . -`
subdomain="bbl.${iaas}.${domain}"
subdomain_token=`echo ${subdomain} | tr . -`

om_version_regex="^2\.0\.[0-9]+$"
pas_version_regex="^2\.0\.[0-9]+$"

lib_dir="${BASEDIR}/lib"
state_dir="${BASEDIR}/state"
key_dir="${BASEDIR}/keys"
patch_dir="${BASEDIR}/patches"
workdir="${BASEDIR}/work"
etc_dir="${BASEDIR}/etc"
manifest_dir="${BASEDIR}/manifests"
params_dir="${BASEDIR}/params"

# certificate configuration
certbot_dir=/usr/local/etc/certbot
ca_dir=${certbot_dir}/live
ca_cert_file=${key_dir}/letsencrypt.pem

cloud_config_vars_file=${state_dir}/vars/cloud-config-vars.yml
bbl_terraform_vars_file=${state_dir}/vars/bbl.tfvars

. ${lib_dir}/${iaas}/env.sh
. ${lib_dir}/${iaas}/bbl_env.sh

if [ -f "${state_dir}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address --state-dir ${state_dir} | cut -d':' -f1 `
  env_id=`bbl env-id --state-dir ${state_dir}`
  short_id=`bbl env-id --state-dir ${state_dir} | sed s/bbl-env-// | cut -dt -f1`
else
  env_id=${subdomain_token}
fi

dns_zone=`echo ${subdomain} | tr . -`
dns_ttl=60

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi

if [ -f "${bbl_terraform_vars_file}" ] ; then
  bbl_vars="$(sed -e 's/:[^:\/\/]/="/;' ${bbl_terraform_vars_file} | grep "^short_env_id")"
  eval "${bbl_vars}"
  short_id=${short_env_id}
fi
