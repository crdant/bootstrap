variable "vault_port" {
  type = "string"
}

resource "google_compute_firewall" "vault" {
  name    = "${var.env_id}-vault"
  network = "${google_compute_network.bbl-network.name}"

  allow {
    protocol = "tcp"
    ports    = [ "${var.vault_port}" ]
  }

  target_tags = [ "vault" ]
}

resource "google_compute_address" "vault" {
  name = "${var.env_id}-vault"
}

resource "google_compute_target_pool" "vault" {
  name = "${var.env_id}-vault"
}

resource "google_compute_forwarding_rule" "vault" {
  name       = "${var.env_id}-vault"
  target     = "${google_compute_target_pool.vault.self_link}"
  ip_address = "${google_compute_address.vault.self_link}"
  port_range = "${var.vault_port}"
}

output "vault_lb_target_pool" {
  value = "${google_compute_target_pool.vault.name}"
}
