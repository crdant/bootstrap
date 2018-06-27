data "terraform_remote_state" "pcf_pipelines" {
  backend = "gcs"
  config {
    bucket  = "${local.short_env_id}-terraform-state"
  }
}
