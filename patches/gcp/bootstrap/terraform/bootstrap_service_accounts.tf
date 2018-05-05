variable "bbl_service_account" {
  type = "string"
}

resource "google_service_account" "bootstrap_service_account" {
  account_id   = "${var.bootstrap_service_account}"
  display_name = "BOSH Boot Loader (bbl)"
}

resource "google_service_account_iam_binding" "bootstrap_account_iam" {
  service_account_id = "${var.bbl_service_account}"
  role        = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.bootstrap_service_account.email}",
  ]
}

output "bbl_service_account" {
  value = "${google_service_account}"
}
