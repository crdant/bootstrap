account=cdantonio@pivotal.io
email=${account}
domain=crdant.io
project=fe-cdantonio

domain_token=`echo ${domain} | tr . -`
subdomain="bbl.gcp.${domain}"

region="us-central1"
storage_location="us"
availability_zone_1="${region}-f"
availability_zone_2="${region}-c"
availability_zone_3="${region}-b"

# TO DO: fixed up to env_id next time I tear down
service_account_name=`echo ${subdomain} | tr . -`
service_account="${service_account_name}@${project}.iam.gserviceaccount.com"

key_dir="${BASEDIR}/keys"
key_file="${key_dir}/${project}-${service_account_name}.json"
workdir="${BASEDIR}/work"
etc_dir="${BASEDIR}/etc"
manifest_dir="${BASEDIR}/manifests"

if [ -f "${BASEDIR}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" | cut -d':' -f1 `
  env_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}"`
  # reversing the string allows us to get around a 't' being in the lake name without resorting to awk, perl, etc.
  short_id=`bbl env-id --gcp-service-account-key "${key_file}" --gcp-project-id "${project}" | sed s/bbl-env-// | rev | cut -dt -f2- | rev`
else
  env_id=`echo ${subdomain} | tr . -`
fi

dns_zone=`echo ${subdomain} | tr . -`
dns_ttl=60

if [ -f "${workdir}/bbl-env.sh" ] ; then
  . ${workdir}/bbl-env.sh
fi
