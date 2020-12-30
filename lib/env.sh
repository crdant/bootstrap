account=cdantonio@pivotal.io
email=${account}
iaas=azure

domain=crdant.io
domain_token=`echo ${domain} | tr . -`
subdomain="bbl.${iaas}.${domain}"

# for Google
project=fe-cdantonio
region="us-central1"
storage_location="us"
availability_zone_1="${region}-f"
availability_zone_2="${region}-c"
availability_zone_3="${region}-b"
service_account_name=`echo ${subdomain} | tr . -`
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"

# for azure
azure_client_id=

# flags for calling bbl
if [ "${iaas}" = "gcp" ] ; then
  iaas_auth_flag="--gcp-service-account-key ${key_file}"
  iaas_location_flag="--gcp-service-account-key ${key_file}"
elif [ "${iaas}" = "azure" ] ; then
  iaas_auth_flag="--azure-client-id ${client_id}"
fi


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

if [ -f "${BASEDIR}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address $iaas_auth_flag| cut -d':' -f1 `
  env_id=`bbl env-id --gcp-service-account-key "${key_file}"`
  short_id=`bbl env-id $iaas_auth_flag| sed s/bbl-env-// | cut -dt -f1`
else
  env_id=`echo ${subdomain} | tr . -`
fi

dns_zone=`echo ${subdomain} | tr . -`
dns_ttl=60

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi
