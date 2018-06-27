resource "google_storage_bucket" "pipeline_statefile_bucket" {
  name       = "${local.short_env_id}-terraform-state"
  versioning = [ { enabled =  "true" } ]
}

resource "google_storage_bucket_acl" "pipeline_statefile_permissions" {
  bucket = "${google_storage_bucket.pipeline_statefile_bucket.name}"

  role_entity = [
    "WRITER:user-${google_service_account.pcf_service_account.email}",
  ]
}

resource "google_storage_bucket" "mysql_backup_bucket" {
  name       = "${local.short_env_id}-mysql-backup-bucket"
  versioning = [ { enabled = "true" } ]
}

resource "google_storage_bucket_acl" "mysql_backup_permissions" {
  bucket = "${google_storage_bucket.mysql_backup_bucket.name}"

  role_entity = [
    "WRITER:user-${google_service_account.pcf_service_account.email}",
  ]
}

output "pipeline_statefile_bucket" {
  value = "${google_storage_bucket.pipeline_statefile_bucket.name}"
}

output "mysql_backup_bucket" {
  value = "${google_storage_bucket.mysql_backup_bucket.name}"
}
