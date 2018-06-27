variable "email" {
  type = "string"
}

variable "service_account_file" {
  type = "string"
}

variable "key_dir" {
  type = "string"
}

locals {
  env_components = "${split("-", var.env_id)}"
  short_env_id = "${join("-", slice(local.env_components, 0, 3))}"
}

output "short_env_id" {
  value = "${local.short_env_id}"
}
