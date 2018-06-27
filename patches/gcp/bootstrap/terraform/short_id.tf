locals {
  short_env_id = "${substr(var.env_id, 0, min(20, length(var.env_id)))}"
}

output "short_env_id" {
  value = "${local.short_env_id}"
}
