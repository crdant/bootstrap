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
    provider = "gcloud"

    config {
      GCE_SERVICE_ACCOUNT_FILE="${local_file.service_account_key.filename}"
      GCE_PROJECT="${var.project_id}"
    }
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
