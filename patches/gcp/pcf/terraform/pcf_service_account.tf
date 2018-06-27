resource "google_service_account" "pcf_service_account" {
  account_id   = "${local.short_env_id}-pcf"
  display_name = "Automated PCF install (${var.env_id})"
}

resource "google_service_account_key" "pcf_service_account" {
  service_account_id = "${google_service_account.pcf_service_account.name}"
}

resource "google_project_iam_binding" "pcf_account_iam" {
  role        = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.pcf_service_account.email}",
  ]
}

resource "local_file" "pcf_service_account_key" {
  content  = "${base64decode(google_service_account_key.pcf_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.pcf_service_account.email}.json"
}
