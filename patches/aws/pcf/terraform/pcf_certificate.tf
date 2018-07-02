variable "pcf_subdomain" {
  type = "string"
}

variable "pcf_system_subdomain" {
  type = "string"
}

variable "pcf_apps_subdomain" {
  type = "string"
}

locals {
  pcf_uaa_subdomain = "*.uaa.${pcf_system_subdomain}.${var.pcf_subdomain}"
  pcf_login_subdomain = "*.login.${pcf_system_subdomain}.${var.pcf_subdomain}"
}

resource "acme_certificate" "pcf_wildcard" {
  account_key_pem           = "${acme_registration.letsencrypt.account_key_pem}"
  common_name               = "${var.pcf_subdomain}"
  subject_alternative_names = [
    "*.${var.pcf_system_subdomain}.${var.pcf_subdomain}"
    "*.${local.pcf_uaa_subdomain}.${var.pcf_subdomain}"
    "*.${local.pcf_login_subdomain}.${var.pcf_subdomain}"
    "*.${var.pcf_apps_subdomain}.${var.pcf_subdomain}"
  ]

  dns_challenge {
    provider = "route53"

    config {
      AWS_ACCESS_KEY_ID     = "${var.access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.secret_key}"
      AWS_DEFAULT_REGION    = "${var.region}"
    }
  }
}

resource "aws_iam_server_certificate" "pcf_wildcard" {
  name_prefix = "${var.env_id}"
  certificate_body = "${acme_certificate.pcf_wildcard.certificate_pem}"
  certificate_chain = "${acme_certificate.pcf_wildcard.issuer_pem}"
  private_key = "${acme_certificate.pcf_wildcard.private_key_pem}"
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

output "pcf_wildcard_cert_arn" {
  value = "${aws_iam_server_certificate.pcf_wildcard.arn}"
}
