ACCOUNT=cdantonio@pivotal.io
DOMAIN=crdant.io
PROJECT=fe-cdantonio

DOMAIN_TOKEN=`echo ${DOMAIN} | tr . -`
SUBDOMAIN="gcp.${DOMAIN}"
SUBDOMAIN_TOKEN=`echo ${SUBDOMAIN} | tr . -`

ENVIRONMENT_NAME="bbl-${SUBDOMAIN_TOKEN}-jump"

REGION="us-east1"
STORAGE_LOCATION="us"
AVAILABILITY_ZONE="${REGION}-d"

DNS_ZONE="${SUBDOMAIN}"
DNS_TTL=60

SERVICE_ACCOUNT_NAME="${ENVIRONMENT_NAME}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com"

KEYDIR="${BASEDIR}/keys"
WORKDIR="${BASEDIR}/work"
KEYFILE="${KEYDIR}/${PROJECT}-${SERVICE_ACCOUNT_NAME}.json"
MANIFEST_DIR="${BASEDIR}/manifests"

if [ -f "${BASEDIR}/bbl-state.json" ] ; then
  JUMPBOX=`jq -r '.jumpbox.url' ${BASEDIR}/bbl-state.json | cut -d':' -f1 `
fi
