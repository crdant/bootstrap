account=cdantonio@pivotal.io
domain=crdant.io
project=fe-cdantonio

domain_token=`echo ${domain} | tr . -`
subdomain="bbl.gcp.${domain}"

region="us-east1"
storage_location="us"
availability_zone="${region}-d"

if [ -f "${BASEDIR}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address | cut -d':' -f1 `
  env_id=`bbl env-id`
else
  env_id=`echo ${subdomain} | tr . -`
fi

dns_zone="${env_id}-dns"
dns_ttl=60

service_account_name="${ENVIRONMENT_NAME}"
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"

key_dir="${BASEDIR}/keys"
key_file="${key_dir}/${project}-${service_account_name}.json"
workdir="${BASEDIR}/work"
etc_dir="${BASEDIR}/etc"
manifest_dir="${BASEDIR}/manifests"

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi
