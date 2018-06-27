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
    provider = "gcloud"

    config {
      GCE_SERVICE_ACCOUNT_FILE="${local_file.service_account_key.filename}"
      GCE_PROJECT="${var.project_id}"
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
