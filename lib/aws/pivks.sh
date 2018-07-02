generate_cluster_template() {
  name=${1}
  cluster_name=${name}-cluster
  dns_name=${name}.pks.pcf.bbl.gcp.crdant.io

  cluster_details="$(pks cluster ${cluster_name} --json)"

  # grab info about the master...should be a data element but not available in the provider
  uuid="$(echo $cluster_details | jq --raw-output '.uuid')"

  cat <<CLUSTER_TERRAFORM > ${state_dir}/terraform/${cluster_name}.tf
CLUSTER_TERRAFORM
}
