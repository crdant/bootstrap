# master service account

resource "google_service_account" "pks_service_account" {
  account_id   = "${local.short_env_id}-pks-master"
  display_name = "Automated PKS install master service account (${var.env_id})"
}

resource "google_service_account_key" "pks_service_account" {
  service_account_id = "${google_service_account.pks_service_account.name}"
}

resource "google_project_iam_member" "pks_service_account" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "google_project_iam_member" "pks_service_account_instance" {
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "google_project_iam_member" "pks_service_account_network" {
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "google_project_iam_member" "pks_service_account_disk" {
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "google_project_iam_member" "pks_service_account_storage" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "google_project_iam_member" "pks_service_account_user" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.pks_service_account.email}"
}

resource "local_file" "pks_service_account_key" {
  content  = "${base64decode(google_service_account_key.pks_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.pks_service_account.email}.json"
}

output "pks_service_account_id" {
  value = "${google_service_account.pks_service_account.email}"
}

# worker service account

resource "google_service_account" "pks_worker_service_account" {
  account_id   = "${local.short_env_id}-pks-worker"
  display_name = "Automated PKS install worker service account (${var.env_id})"
}

resource "google_service_account_key" "pks_service_account" {
  service_account_id = "${google_service_account.pks_service_account.name}"
}

resource "google_project_iam_member" "pks_worker_service_account" {
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.pks_worker_service_account.email}"
}

resource "local_file" "pks_worker_service_account_key" {
  content  = "${base64decode(google_service_account_key.pks_worker_service_account.private_key)}"
  filename = "${var.key_dir}/${google_service_account.pks_worker_service_account.email}.json"
}

output "pks_worker_service_account_id" {
  value = "${google_service_account.pks_worker_service_account.email}"
}
