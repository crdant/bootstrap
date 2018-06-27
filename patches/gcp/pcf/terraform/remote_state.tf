data "terraform_remote_state" "pcf_pipelines" {
  backend = "gcs"
  config {
    bucket  = "${local.short_env_id}-terraform-state"
    credentials = "${var.key_dir}/${google_service_account.pcf_service_account.email}.json"
  }
}
