variable "concourse_cert_file" {
  type = "string"
}

variable "concourse_key_file" {
  type = "string"
}

resource "acme_certificate" "concourse" {
  account_key_pem           = "${acme_registration.letsencrypt.account_key_pem}"
  common_name               = "${var.concourse_host}"

  dns_challenge {
    provider = "route53"

    config {
      AWS_ACCESS_KEY_ID     = "${var.access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.secret_key}"
      AWS_DEFAULT_REGION    = "${var.region}"
    }
  }
}

resource "local_file" "concourse_cert_file" {
  content  = "${acme_certificate.concourse.certificate_pem}"
  filename = "${var.concourse_cert_file}"
}

resource "local_file" "concourse_key_file" {
  content  = "${acme_certificate.concourse.private_key_pem}"
  filename = "${var.concourse_key_file}"
}
