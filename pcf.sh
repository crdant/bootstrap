#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"

concourse_team=pcf
concourse_target=${env_id}-${concourse_team}
concourse_url=`./concourse.sh url`
pcf_concourse_user=pivotal

pcf_install_pipeline="deploy-pcf"
pcf_pipelines_remote="https://github.com/pivotal-cf/pcf-pipelines.git"
pcf_service_account_name=`echo "pcf-${env_id}" | sed s/bbl-env-//`
pcf_service_account="${pcf_service_account_name}@${project}.iam.gserviceaccount.com"
pcf_key_file=${key_dir}/${project}-${pcf_service_account_name}.json

prepare_concourse() {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
  concourse_admin="admin"
  admin_password=`safe get secret/bootstrap/concourse/admin:value`
  fly --target ${env_id} login --team-name main --ca-cert ${key_dir}/atc-${env_id}.crt --concourse-url=${concourse_url} --username=${concourse_admin} --password=${admin_password}

  safe set secret/bootstrap/concourse/${pcf_concourse_user} value=`generate_passphrase 4`
  pcf_concourse_password=`safe get secret/bootstrap/concourse/${pcf_concourse_user}:value`
  fly --target ${env_id} set-team --team-name ${concourse_team} --basic-auth-username=${pcf_concourse_user} --basic-auth-password=${pcf_concourse_password}
}

concourse_login() {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
  pcf_concourse_password=`safe get secret/bootstrap/concourse/pivotal:value`
  fly --target ${concourse_target} login --team-name ${concourse_team} --ca-cert ${key_dir}/atc-${env_id}.crt --concourse-url=${concourse_url} --username=${pcf_concourse_user} --password=${pcf_concourse_password}
}

service_accounts () {
  echo "Creating a service account for PCF..."

  gcloud iam service-accounts --project "${project}" create "${pcf_service_account_name}" --display-name "PCF Bootstraped by BOSH Boot Loader (bbl) and Concourse" --no-user-output-enabled
  gcloud projects add-iam-policy-binding "${project}" --member "serviceAccount:${pcf_service_account}" --role "roles/editor" --no-user-output-enabled

  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.instanceAdmin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.networkAdmin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.storageAdmin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/storage.admin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/cloudsql.admin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/dns.admin" --no-user-output-enabled
  gcloud projects add-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.securityAdmin" --no-user-output-enabled

  gcloud iam service-accounts --project "${project}" keys create "${pcf_key_file}"  --iam-account "${pcf_service_account}"
}

download () {
  if [ ! -d ${workdir}/pcf_pipelines ] ; then
    git clone ${pcf_pipelines_remote} ${workdir}/pcf_pipelines
  else
    pushd ${workdir}/pcf_pipelines
    git pull ${pcf_pipelines_remote}
    popd
  fi
}

safe_auth () {
  jq --raw-output '.auth.client_token' ${key_dir}/conrad-${env_id}-token.json | safe auth token
}

secrets () {
  local secret_root="concourse/${concourse_team}/${pcf_install_pipeline}"
  echo $secret_root
  exit 0
  safe_auth

  safe set ${secret_root}/gcp_service_account_key value="$(cat ${pcf_key_file})"
  # N.B. set these two on your own, No API for them
  # safe set ${secret_root}/gcp_storage_access_key value=
  # safe set ${secret_root}/gcp_storage_secret_key:
  safe set ${secret_root}/git_private_key value="$(cat ${HOME}/.ssh/concourse_github)"
  safe set ${secret_root}/pivnet_token value=${PIVNET_TOKEN}
  safe set ${secret_root}/pcf_opsman_admin_username value=admin
  safe gen ${secret_root}/pcf_opsman_admin_password value

  # Usernames must be 16 characters or fewer
  safe set ${secret_root}/db_diego_username value=pcf-diego
  safe gen ${secret_root}/db_diego_password value
  safe set ${secret_root}/db_notifications_username value=pcf-notification
  safe gen ${secret_root}/db_notifications_password value
  safe set ${secret_root}/db_autoscale_username value=pcf-autoscale
  safe gen ${secret_root}/db_autoscale_password value
  safe set ${secret_root}/db_uaa_username value=uaa
  safe gen ${secret_root}/db_uaa_password value
  safe set ${secret_root}/db_app_usage_service_username value=pcf-app-usage
  safe gen ${secret_root}/db_app_usage_service_password value
  safe set ${secret_root}/db_ccdb_username value=pcf-ccdb
  safe gen ${secret_root}/db_ccdb_password value
  safe set ${secret_root}/db_routing_username value=pcf-routing
  safe gen ${secret_root}/db_routing_password value

  safe set ${secret_root}/db_accountdb_username value=pcf-accounts
  safe gen ${secret_root}/db_accountdb_password value
  safe set ${secret_root}/db_networkpolicyserverdb_username value=pcf-policy-server
  safe gen ${secret_root}/db_networkpolicyserverdb_password value
  safe set ${secret_root}/db_nfsvolumedb_username value=pcf-nfs-volumes
  safe gen ${secret_root}/db_nfsvolumedb_password value
  safe set ${secret_root}/db_silk_username value=pcf-silk
  safe gen ${secret_root}/db_silk_password value
  safe set ${secret_root}/db_locket_username value=pcf-locket
  safe gen ${secret_root}/db_locket_password value
}

params() {
  cat <<PARAMS > ${workdir}/install-pcf.yml

  # GCP project to create the infrastructure in
  gcp_project_id: ${project}

  # Identifier to prepend to GCP infrastructure names/labels
  gcp_resource_prefix: pcf-${env_id}

  # GCP region
  gcp_region: ${region}

  # GCP Zones
  gcp_zone_1: ${availability_zone_1}
  gcp_zone_2: ${availability_zone_2}
  gcp_zone_3: ${availability_zone_3}

  # Storage Location
  gcp_storage_bucket_location: ${storage_location}

  terraform_statefile_bucket:

  # Elastic Runtime SSL configuration
  # Set pcf_ert_ssl_cert to 'generate' if you'd like a self-signed cert to be made
  pcf_ert_ssl_cert: generate
  pcf_ert_ssl_key:

  # Elastic Runtime Domain
  pcf_ert_domain: ${subdomain} # This is the domain you will access ERT with
  opsman_domain_or_ip_address: ${subdomain} # This should be your pcf_ert_domain with "opsman." as a prefix

  ert_errands_to_disable: none

  # PCF Operations Manager minor version to install
  opsman_major_minor_version: ^1\.11\..*$

  # PCF Elastic Runtime minor version to install
  ert_major_minor_version: ^1\.11\..*$

  mysql_monitor_recipient_email: ${email} # Email address for sending mysql monitor notifications
  mysql_backups: disable   # Whether to enable MySQL backups. (disable|s3|scp)
PARAMS
}

pipeline () {
  ${BASEDIR}/concourse.sh login
  fly --target ${concourse_target} set-pipeline --pipeline ${pcf_install_pipeline} \
    --config ${workdir}/pcf_pipelines/install-pcf/gcp/pipeline.yml \
    --load-vars-from ${workdir}/install-pcf.yml
  fly --target ${concourse_target} unpause-pipeline --pipeline ${pcf_install_pipeline} \
    --config ${workdir}/pcf_pipelines/install-pcf/gcp/pipeline.yml \
    --load-vars-from ${workdir}/install-pcf.yml
}

install () {
    fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/bootstrap-terraform-state
    fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/create-infrastructure
    fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/configure-director
}

teardown () {
  fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/wipe-env
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      prepare )
        prepare_concourse
        ;;
      login )
        concourse_login
        ;;
      accounts )
        service_accounts
        ;;
      security )
        service_accounts
        ;;
      secrets )
        secrets
        ;;
      params )
        params
        ;;
      download)
        download
        ;;
      deploy )
        download
        pipeline
        install
        ;;
      pipeline )
        pipeline
        ;;
      install )
        install
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

accounts
prepare_concourse
concourse_login
download
secrets
params
pipeline
install
init
