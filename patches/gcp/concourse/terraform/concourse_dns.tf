variable "concourse_host" {
  type = "string"
}

resource "google_dns_record_set" "concourse" {
  name    = "${var.concourse_host}."
  type = "A"
  ttl  = "${var.dns_ttl}"

  managed_zone = "${google_dns_managed_zone.bootstrap_dns_zone.name}"

  rrdatas = [ "${google_compute_address.concourse-address.address}" ]
}
