resource "google_service_account" "pcf_service_account" {
  account_id   = "${local.short_env_id}-pcf"
  display_name = "Automated PCF install (${var.env_id})"
}

resource "google_service_account_key" "pcf_service_account" {
  service_account_id = "${google_service_account.pcf_service_account.name}"
}

resource "google_project_iam_member" "pcf_service_account" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_instance" {
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_network" {
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_disk" {
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_storage" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_user" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "google_project_iam_member" "pcf_service_account_token" {
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.pcf_service_account.email}"
}

resource "local_file" "pcf_service_account_key" {
  content  = "${base64decode(google_service_account_key.pcf_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.pcf_service_account.email}.json"
}
