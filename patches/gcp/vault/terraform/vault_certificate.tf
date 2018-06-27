variable "vault_cert_file" {
  type = "string"
}

variable "vault_key_file" {
  type = "string"
}

resource "acme_certificate" "vault" {
  account_key_pem           = "${acme_registration.letsencrypt.account_key_pem}"
  common_name               = "${var.vault_host}"

  dns_challenge {
    provider = "gcloud"

    config {
      GCE_SERVICE_ACCOUNT_FILE="${local_file.service_account_key.filename}"
      GCE_PROJECT="${var.project_id}"
    }
  }
}

resource "local_file" "vault_cert_file" {
  content  = "${acme_certificate.vault.certificate_pem}"
  filename = "${var.vault_cert_file}"
}

resource "local_file" "vault_key_file" {
  content  = "${acme_certificate.vault.private_key_pem}"
  filename = "${var.vault_key_file}"
}
