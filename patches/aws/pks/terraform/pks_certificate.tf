variable "pks_subdomain" {
  type = "string"
}

variable "pks_wildcard_key" {
  type = "string"
}

variable "pks_wildcard_cert" {
  type = "string"
}

resource "acme_certificate" "pks" {
  account_key_pem           = "${acme_registration.letsencrypt.account_key_pem}"
  common_name               = "${var.pks_subdomain}"
  subject_alternative_names = [
    "*.${var.pks_subdomain}"
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

resource "aws_iam_server_certificate" "pks" {
  name_prefix = "${var.env_id}"
  certificate_body = "${acme_certificate.pks.certificate_pem}"
  certificate_chain = "${acme_certificate.pks.issuer_pem}"
  private_key = "${acme_certificate.pks.private_key_pem}"
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "local_file" "pks_cert_file" {
  content  = "${acme_certificate.pks.certificate_pem}"
  filename = "${var.pks_wildcard_cert}"
}

resource "local_file" "pks_key_file" {
  content  = "${acme_certificate.pks.private_key_pem}"
  filename = "${var.pks_wildcard_key}"
}
