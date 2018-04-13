account=cdantonio@pivotal.io
email=${account}
domain=crdant.io
iaas=aws

domain_token=`echo ${domain} | tr . -`
subdomain="bbl.${iaas}.${domain}"

lib_dir="${BASEDIR}/lib"
state_dir="${BASEDIR}/state"
key_dir="${BASEDIR}/keys"
workdir="${BASEDIR}/work"
etc_dir="${BASEDIR}/etc"
manifest_dir="${BASEDIR}/manifests"

# certificate configuration
certbot_dir=/usr/local/etc/certbot

. ${lib_dir}/${iaas}/env.sh
. ${lib_dir}/${iaas}/bbl_env.sh

if [ -f "${state_dir}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address --state-dir ${state_dir} | cut -d':' -f1 `
  env_id=`bbl env-id --state-dir ${state_dir}`
  short_id=`bbl env-id --state-dir ${state_dir} | sed s/bbl-env-// | cut -dt -f1`
else
  env_id=`echo ${subdomain} | tr . -`
fi

dns_zone=`echo ${subdomain} | tr . -`
dns_ttl=60

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi
