resource "google_service_account" "pks_service_account" {
  account_id   = "${local.short_env_id}-pks"
  display_name = "Automated PKS install (${var.env_id})"
}

resource "google_service_account_key" "pks_service_account" {
  service_account_id = "${google_service_account.pks_service_account.name}"
}

resource "google_project_iam_member" "pks_service_account" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "local_file" "pks_service_account_key" {
  content  = "${base64decode(google_service_account_key.pks_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.pks_service_account.email}.json"
}
