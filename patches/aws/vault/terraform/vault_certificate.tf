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
    provider = "route53"

    config {
      AWS_ACCESS_KEY_ID     = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
      AWS_DEFAULT_REGION    = "${var.region}"
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
