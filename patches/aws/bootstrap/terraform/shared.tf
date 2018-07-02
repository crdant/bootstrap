variable "domain" {
  type = "string"
}

variable "email" {
  type = "string"
}

variable "key_dir" {
  type = "string"
}

output "short_env_id" {
  value = "${var.short_env_id}"
}
