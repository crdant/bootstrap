variable "pks_api_port" {
  type = "string"
}

variable "pks_uaa_port" {
  type = "string"
}

resource "google_compute_firewall" "pks" {
  name    = "${var.env_id}-pks-api"
  # shift to remote state
  network = "pcf-${local.short_env_id}-virt-net"

  allow {
    protocol = "tcp"
    ports    = [ "${var.pks_api_port}", "${var.pks_uaa_port}" ]
  }

  target_tags = [ "${var.env_id}-pks-api" ]
}

resource "google_compute_address" "pks_api" {
  name = "${var.env_id}-pks-api"
}

resource "google_compute_target_pool" "pks_api" {
  name = "${var.env_id}-pks-api"
}

resource "google_compute_forwarding_rule" "pks_api" {
  name       = "${var.env_id}-pks-api"
  target     = "${google_compute_target_pool.pks_api.self_link}"
  ip_address = "${google_compute_address.pks_api.self_link}"
  port_range = "${var.pks_api_port}"
}

resource "google_compute_forwarding_rule" "pks_uaa" {
  name       = "${var.env_id}-pks-uaa"
  target     = "${google_compute_target_pool.pks_api.self_link}"
  ip_address = "${google_compute_address.pks_api.self_link}"
  port_range = "${var.pks_uaa_port}"
}

output "pks_api_lb_target_pool" {
  value = "${google_compute_target_pool.pks_api.name}"
}
