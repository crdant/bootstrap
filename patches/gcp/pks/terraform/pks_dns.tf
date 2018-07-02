variable "pks_wildcard" {
  type = "string"
}

data "google_dns_managed_zone" "env_dns_zone" {
  name        = "pcf-${local.short_env_id}-zone"
}

resource "google_dns_record_set" "pks" {
  name    = "${var.pks_wildcard}."
  type = "A"
  ttl  = "${var.dns_ttl}"

  managed_zone = "${data.google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = [ "${google_compute_address.pks_api.address}" ]
}
