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
    provider = "gcloud"

    config {
      GCE_SERVICE_ACCOUNT_FILE="${local_file.service_account_key.filename}"
      GCE_PROJECT="${var.project_id}"
    }
  }
}

resource "local_file" "pcf_cert_file" {
  content  = "${acme_certificate.pcf.certificate_pem}"
  filename = "${var.pcf_wildcard_cert}"
}

resource "local_file" "pcf_key_file" {
  content  = "${acme_certificate.pcf.private_key_pem}"
  filename = "${var.pcf_wildcard_key}"
}

resource "local_file" "pcf_chain_file" {
  content  = "${acme_certificate.pcf.issuer_pem}"
  filename = "${var.pcf_wildcard_chain}"
}
