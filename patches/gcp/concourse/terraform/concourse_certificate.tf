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
    provider = "gcloud"

    config {
      GCE_SERVICE_ACCOUNT_FILE="${local_file.service_account_key.filename}"
      GCE_PROJECT="${var.project_id}"
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
