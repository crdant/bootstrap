variable "ldap_port" {
  type = "string"
}

resource "google_compute_firewall" "ldap" {
  name    = "${var.env_id}-ldap"
  network = "${google_compute_network.bbl-network.name}"

  allow {
    protocol = "tcp"
    ports    = [ "${var.ldap_port}" ]
  }

  target_tags = [ "ldap" ]
}

resource "google_compute_address" "ldap" {
  name = "${var.env_id}-ldap"
}

resource "google_compute_target_pool" "ldap" {
  name = "${var.env_id}-ldap"
}

resource "google_compute_forwarding_rule" "ldap" {
  name       = "${var.env_id}-ldap"
  target     = "${google_compute_target_pool.ldap.self_link}"
  ip_address = "${google_compute_address.ldap.self_link}"
  port_range = "${var.ldap_port}"
}

output "ldap_lb_target_pool" {
  value = "${google_compute_target_pool.ldap.name}"
}
