variable "bootstrap_domain" {
  type = "string"
}

resource "google_dns_managed_zone" "bootstrap_dns_zone" {
  name     = "${var.env_id}-zone"
  dns_name = "${var.bootstrap_domain}"
  description = "DNS zone for the ${var.env_id} bootstrap environment"
}

output "bootstrap_domain_dns_servers" {
  value = "${google_dns_managed_zone.bootstrap_dns_zone.name_servers}"
}
