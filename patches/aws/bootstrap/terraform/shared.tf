variable "email" {
  type = "string"
}

variable "key_dir" {
  type = "string"
}

locals {
  env_components = "${split("-", var.env_id)}"
}
