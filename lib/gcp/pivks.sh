generate_cluster_template() {
  name=${1}
  cluster_name=${name}-cluster
  dns_name=${name}.pks.pcf.bbl.gcp.crdant.io

  cluster_details="$(pks cluster ${cluster_name} --json)"

  # grab info about the master...should be a data element but not available in the provider
  uuid="$(echo $cluster_details | jq --raw-output '.uuid')"
  master_instance="$(gcloud compute instances list --filter="labels.job:master AND labels.deployment:service-instance-${uuid}" --format=json)"

  # N.B. adjust for multi-master at some point
  master_name="$(echo ${master_instance} | jq --raw-output '.[].name')"
  master_zone_uri="$(echo ${master_instance} | jq --raw-output '.[].zone')"
  master_zone="${master_zone_uri##*/}"

  cat <<CLUSTER_TERRAFORM > ${state_dir}/terraform/${cluster_name}.tf
resource "google_compute_address" "pks_cluster_${name}" {
name = "\${var.env_id}-pks-${cluster_name}"
}

resource "google_dns_record_set" "pks_cluster_${name}" {
name    = "${dns_name}."
type = "A"
ttl  = "\${var.dns_ttl}"

managed_zone = "\${data.google_dns_managed_zone.env_dns_zone.name}"

rrdatas = [ "\${google_compute_address.pks_cluster_${name}.address}" ]
}

resource "google_compute_target_pool" "pks_cluster_${name}" {
name = "\${var.env_id}-pks-cluster"
instances = [
  "${master_zone}/${master_name}"
]
}

resource "google_compute_forwarding_rule" "pks_cluster_${name}" {
name       = "\${var.env_id}-pks-${cluster_name}"
target     = "\${google_compute_target_pool.pks_cluster_${name}.self_link}"
ip_address = "\${google_compute_address.pks_cluster_${name}.self_link}"
port_range = "8443"
}

output "pks_cluster_lb_target_pool" {
value = "\${google_compute_target_pool.pks_cluster_${name}.name}"
}
CLUSTER_TERRAFORM
}
