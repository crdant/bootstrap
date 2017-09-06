#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/secrets.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"

concourse_team=pcf
concourse_target=${env_id}-${concourse_team}
concourse_url=`./concourse.sh url`
pcf_concourse_user=pivotal

pcf_install_pipeline="deploy-pcf"
pcf_pipelines_remote="https://github.com/pivotal-cf/pcf-pipelines.git"
pcf_pipelines_local=${workdir}/pcf-pipelines
pcf_pipelines_version="v0.16.0"
pipeline_file="${workdir}/pcf-pipelines/install-pcf/gcp/pipeline.yml"
parameter_file="${workdir}/${env_id}-${pcf_install_pipeline}-params.yml"

pcf_service_account_name="pcf-${short_id}"
pcf_service_account="${pcf_service_account_name}@${project}.iam.gserviceaccount.com"
pcf_key_file=${key_dir}/${project}-${pcf_service_account_name}.json
pcf_dns_zone="pcf-${short_id}-zone"         # TO DO: See if I can get this from the Terraform state (or even the pipelines terraform file)
pcf_subdomain="pcf.${subdomain}"

terraform_statefile_bucket="${env_id}-bucket"

mysql_backup_bucket=${short_id}-mysql-backups
mysql_backup_schedule="0 0/72 * * *"

prepare_concourse() {
  safe_auth_bootstrap
  concourse_admin="admin"
  admin_password=`safe get secret/bootstrap/concourse/${concourse_admin}:value`
  fly --target ${env_id} login --team-name main --ca-cert ${key_dir}/atc-${env_id}.crt --concourse-url=${concourse_url} --username=${concourse_admin} --password=${admin_password}
  fly --target ${env_id} sync

  safe set secret/bootstrap/concourse/${pcf_concourse_user} value=`generate_passphrase 4`
  pcf_concourse_password=`safe get secret/bootstrap/concourse/${pcf_concourse_user}:value`
  fly --target ${env_id} set-team --team-name ${concourse_team} --basic-auth-username=${pcf_concourse_user} --basic-auth-password=${pcf_concourse_password}
}

concourse_login() {
  safe_auth_bootstrap
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

buckets () {
  echo "Creating storage buckets..."
  gsutil mb -l ${storage_location} gs://${terraform_statefile_bucket}
  gsutil acl ch -u ${service_account}:O gs://${terraform_statefile_bucket}
  gsutil versioning set on gs://${terraform_statefile_bucket}

  gsutil mb -l ${storage_location} gs://${mysql_backup_bucket}
  gsutil acl ch -u ${service_account}:O gs://${mysql_backup_bucket}
  gsutil versioning set on gs://${mysql_backup_bucket}

}

download () {
  # TODO: Switch to Pivnet?
  pivnet download-product-files --product-slug pcf-automation --release-version ${pcf_pipelines_version} --download-dir ${workdir} --glob "pcf-pipelines-${pcf_pipelines_version}.tgz" --accept-eula
  tar -xzf "${workdir}/pcf-pipelines-${pcf_pipelines_version}.tgz" -C "${workdir}"
  modernize_pipeline
}

modernize_pipeline() {
  sed -i -e 's/{{/((/g' "${pipeline_file}"
  sed -i -e 's/}}/))/g' "${pipeline_file}"
}

safe_auth () {
  jq --raw-output '.auth.client_token' ${key_dir}/conrad-${env_id}-token.json | safe auth token
}

get_secret () {
  local secret_root="concourse/${concourse_team}/${pcf_install_pipeline}"
  local secret="${1}"

  if  [ ${secret} == "concourse" ] ; then
    safe_auth_bootstrap
    safe get secret/bootstrap/concourse/pivotal:value
    return
  fi

  safe_auth
  safe get ${secret_root}/${secret}:value
}

secrets () {
  local secret_root="concourse/${concourse_team}/${pcf_install_pipeline}"
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
  safe set ${secret_root}/db_networkpolicyserverdb_username value=pcf-policy
  safe gen ${secret_root}/db_networkpolicyserverdb_password value
  safe set ${secret_root}/db_nfsvolumedb_username value=pcf-nfs
  safe gen ${secret_root}/db_nfsvolumedb_password value
  safe set ${secret_root}/db_silk_username value=pcf-silk
  safe gen ${secret_root}/db_silk_password value
  safe set ${secret_root}/db_locket_username value=pcf-locket
  safe gen ${secret_root}/db_locket_password value
}

params() {
  cat <<PARAMS > ${parameter_file}

  # GCP project to create the infrastructure in
  gcp_project_id: ${project}

  # Identifier to prepend to GCP infrastructure names/labels
  gcp_resource_prefix: pcf-${short_id}

  # GCP region
  gcp_region: ${region}

  # GCP Zones
  gcp_zone_1: ${availability_zone_1}
  gcp_zone_2: ${availability_zone_2}
  gcp_zone_3: ${availability_zone_3}

  # Storage Location
  gcp_storage_bucket_location: ${storage_location}

  terraform_statefile_bucket: ${terraform_statefile_bucket}

  # Operations Manager Trusted Certificates
  pcf_opsman_trusted_certs: |

  # Elastic Runtime SSL configuration
  # Set pcf_ert_ssl_cert to 'generate' if you'd like a self-signed cert to be made
  pcf_ert_ssl_cert: generate
  pcf_ert_ssl_key:

  # Elastic Runtime Domain
  pcf_ert_domain: ${pcf_subdomain} # This is the domain you will access ERT with
  opsman_domain_or_ip_address: opsman.${pcf_subdomain} # This should be your pcf_ert_domain with "opsman." as a prefix

  ert_errands_to_disable: none

  # PCF Operations Manager minor version to install
  opsman_major_minor_version: ^1\.11\.8*$

  # PCF Elastic Runtime minor version to install
  ert_major_minor_version: ^1\.11\..*$

  mysql_monitor_recipient_email: ${email} # Email address for sending mysql monitor notifications
  mysql_backups: s3   # Whether to enable MySQL backups. (disable|s3|scp)
  mysql_backups_s3_access_key_id: ((gcp_storage_access_key))
  mysql_backups_s3_bucket_name: ${mysql_backup_bucket}
  mysql_backups_s3_bucket_path:
  mysql_backups_s3_cron_schedule: ${mysql_backup_schedule}
  mysql_backups_s3_endpoint_url: https://storage.googleapis.com
  mysql_backups_s3_secret_access_key: ((gcp_storage_secret_key))
  mysql_backups_scp_cron_schedule:
  mysql_backups_scp_destination:
  mysql_backups_scp_key:
  mysql_backups_scp_port:
  mysql_backups_scp_server:
  mysql_backups_scp_user:
PARAMS
}

pipeline () {
  concourse_login
  fly --target ${concourse_target} set-pipeline --pipeline ${pcf_install_pipeline} \
    --config ${pipeline_file} --load-vars-from ${parameter_file}
  fly --target ${concourse_target} unpause-pipeline --pipeline ${pcf_install_pipeline}
}

trigger() {
  job="${1}"
  echo "Triggering job ${1}"
  fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/${job}
  fly --target ${concourse_target} watch -j ${pcf_install_pipeline}/${job}
}

hijack() {
  job="${1}"
  echo "Hijacking job ${1}"
  fly --target ${concourse_target} hijack -j ${pcf_install_pipeline}/${job}
}


bootstrap_terraform() {
  echo "Bootstrapping PCF infrastructure..."
  trigger "bootstrap-terraform-state"
}

create_infrastructure () {
  echo "Creating PCF infrastructure..."
  trigger "create-infrastructure"
  dns
}

dns () {
  # TODO: trap errors and delete transaction file for sanity (mayhaps just rollback with gcloud dns)
  echo "Delegating DNS..."
  local name_servers=( `gcloud dns managed-zones describe "${pcf_dns_zone}" --format json | jq -r  '.nameServers | join(" ")'` )
  local transaction_file="${WORKDIR}/pcf-dns-transaction-${pcf_dns_zone}.xml"

  gcloud dns record-sets transaction start -z "${pcf_dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled

  gcloud dns record-sets transaction add -z "${pcf_dns_zone}" --name "${pcf_subdomain}" --ttl "${dns_ttl}" --type NS "${name_servers[0]}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets transaction add -z "${pcf_dns_zone}" --name "${pcf_subdomain}" --ttl "${dns_ttl}" --type NS "${name_servers[1]}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets transaction add -z "${pcf_dns_zone}" --name "${pcf_subdomain}" --ttl "${dns_ttl}" --type NS "${name_servers[2]}" --transaction-file="${transaction_file}" --no-user-output-enabled
  gcloud dns record-sets transaction add -z "${pcf_dns_zone}" --name "${pcf_subdomain}" --ttl "${dns_ttl}" --type NS "${name_servers[3]}" --transaction-file="${transaction_file}" --no-user-output-enabled

  gcloud dns record-sets transaction execute -z "${pcf_dns_zone}" --transaction-file="${transaction_file}" --no-user-output-enabled
}

configure_director() {
  echo "Configuring Ops Manger Director..."
  trigger "configure-director"
}

install() {
  bootstrap_terraform
  create_infrastructure
  configure_director
}

wipe_env() {
  fly --target ${concourse_target} trigger-job -j ${pcf_install_pipeline}/wipe-env
  fly --target ${concourse_target} watch -j ${pcf_install_pipeline}/wipe-env
}

teardown() {
  wipe_env
  fly --target ${concourse_target} destroy-pipeline -p "${pcf_install_pipeline}"

  gsutil rm -l ${storage_location} gs://${terraform_statefile_bucket}

  gcloud projects remove-iam-policy-binding "${project}" --member "serviceAccount:${pcf_service_account}" --role "roles/editor" --no-user-output-enabled

  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.instanceAdmin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.networkAdmin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.storageAdmin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/storage.admin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/cloudsql.admin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/dns.admin" --no-user-output-enabled
  gcloud projects remove-iam-policy-binding ${project} --member "serviceAccount:${pcf_service_account}" --role "roles/compute.securityAdmin" --no-user-output-enabled

  pcf_key_id=`jq --raw-output '.private_key_id' "${pcf_key_file}"`
  gcloud iam service-accounts --project "${project}" keys delete "${pcf_key_id}"  --iam-account "${pcf_service_account}"
  gcloud iam service-accounts --project "${project}" delete "${pcf_service_account}" --no-user-output-enabled
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      service_accounts | accounts | security )
        service_accounts
        ;;
      buckets | bucket | tfstate )
        buckets
        ;;
      prepare_concourse | prepare )
        prepare_concourse
        ;;
      concourse_login | login )
        concourse_login
        ;;
      download)
        download
        ;;
      secrets )
        secrets
        ;;
      params )
        params
        ;;
      pipeline | pipelines )
        pipeline
        ;;
      install )
        install
        ;;
      deploy )
        download
        pipeline
        install
        ;;
      modernize_pipeline | modernize)
        modernize_pipeline
        ;;
      bootstrap_terraform | bootstrap)
        bootstrap_terraform
        ;;
      create_infrastructure | infrastructure)
        create_infrastructure
        ;;
      configure_director | director | opsman | om)
        configure_director
        ;;
      wipe_env | wipe)
        wipe_env
        ;;
      dns)
        dns
        ;;
      safe_auth)
        safe_auth
        ;;
      get_secret | password | secret)
        get_secret "${2}"
        shift
        ;;
      trigger)
        trigger "${2}"
        shift
        ;;
      hijack)
        hijack "${2}"
        shift
        ;;
      teardown)
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
buckets
download
secrets
params
pipeline
install
