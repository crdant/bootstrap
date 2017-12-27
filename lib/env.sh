account=cdantonio@pivotal.io
email=${account}
domain=crdant.io
project=fe-cdantonio
iaas=gcp

domain_token=`echo ${domain} | tr . -`
subdomain="bbl.${iaas}.${domain}"

region="us-central1"
storage_location="us"
availability_zone_1="${region}-f"
availability_zone_2="${region}-c"
availability_zone_3="${region}-b"

# TO DO: fixed up to env_id next time I tear down
service_account_name=`echo ${subdomain} | tr . -`
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"

state_dir="${BASEDIR}/state"
key_dir="${BASEDIR}/keys"
key_file="${key_dir}/${project}-${service_account_name}.json"
workdir="${BASEDIR}/work"
etc_dir="${BASEDIR}/etc"
manifest_dir="${BASEDIR}/manifests"

# CA configuration
ca_dir=${key_dir}/CA
ca_name="${domain} Certificate Authority"
ca_cert_file=${ca_dir}/`echo ${ca_name} | tr ' ' '_'`.crt
country="US"
state="MA"
city="Cambridge"
organization="${domain}"

if [ -f "${state_dir}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address --state-dir ${state_dir} --gcp-service-account-key "${key_file}" | cut -d':' -f1 `
  env_id=`bbl env-id --state-dir ${state_dir} --gcp-service-account-key "${key_file}"`
  short_id=`bbl env-id --state-dir ${state_dir} --gcp-service-account-key "${key_file}" | sed s/bbl-env-// | cut -dt -f1`
else
  env_id=`echo ${subdomain} | tr . -`
fi

dns_zone=`echo ${subdomain} | tr . -`
dns_ttl=60

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi
