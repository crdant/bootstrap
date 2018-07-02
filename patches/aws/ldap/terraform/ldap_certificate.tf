variable "ldap_cert_file" {
  type = "string"
}

variable "ldap_key_file" {
  type = "string"
}

resource "acme_certificate" "ldap" {
  account_key_pem           = "${acme_registration.letsencrypt.account_key_pem}"
  common_name               = "${var.ldap_host}"

  dns_challenge {
    provider = "route53"

    config {
      AWS_HOSTED_ZONE_ID    = "${aws_route53_zone.bootstrap_dns_zone.zone_id}"
      AWS_ACCESS_KEY_ID     = "${var.access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.secret_key}"
      AWS_DEFAULT_REGION    = "${var.region}"
    }
  }
}

resource "local_file" "ldap_cert_file" {
  content  = "${acme_certificate.ldap.certificate_pem}"
  filename = "${var.ldap_cert_file}"
}

resource "local_file" "ldap_key_file" {
  content  = "${acme_certificate.ldap.private_key_pem}"
  filename = "${var.ldap_key_file}"
}
