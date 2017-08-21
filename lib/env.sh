ACCOUNT=cdantonio@pivotal.io
DOMAIN=crdant.io
PROJECT=fe-cdantonio

DOMAIN_TOKEN=`echo ${DOMAIN} | tr . -`
SUBDOMAIN="gcp.${DOMAIN}"
SUBDOMAIN_TOKEN=`echo ${SUBDOMAIN} | tr . -`

REGION="us-east1"
STORAGE_LOCATION="us"
AVAILABILITY_ZONE="${REGION}-d"

DNS_ZONE="${SUBDOMAIN}"
DNS_TTL=60

SERVICE_ACCOUNT_NAME="${ENVIRONMENT_NAME}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com"

KEYDIR="${BASEDIR}/keys"
KEYFILE="${KEYDIR}/${PROJECT}-${SERVICE_ACCOUNT_NAME}.json"
WORKDIR="${BASEDIR}/work"
ETCDIR="${BASEDIR}/etc"
MANIFEST_DIR="${BASEDIR}/manifests"

if [ -f "${BASEDIR}/bbl-state.json" ] ; then
  jumpbox=`bbl jumpbox-address | cut -d':' -f1 `
  env_id=`bbl env-id`
fi

if [ -f "${WORKDIR}/bbl-env.sh" ] ; then
  . ${WORKDIR}/bbl-env.sh
fi
