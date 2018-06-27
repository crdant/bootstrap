resource "google_service_account" "bootstrap_service_account" {
  account_id   = "${local.short_env_id}"
  display_name = "BOSH Boot Loader (${var.env_id})"
}

resource "google_service_account_key" "bootstrap_service_account" {
  service_account_id = "${google_service_account.bootstrap_service_account.name}"
}

resource "google_project_iam_binding" "bootstrap_account_iam" {
  role        = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.bootstrap_service_account.email}",
  ]
}

resource "local_file" "service_account_key" {
  content  = "${base64decode(google_service_account_key.bootstrap_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.bootstrap_service_account.email}.json"
}
