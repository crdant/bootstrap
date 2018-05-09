variable "pcf_subdomain" {
  type = "string"
}

variable "pcf_wildcard_cert" {
  type = "string"
}

variable "pcf_wildcard_chain" {
  type = "string"
}

variable "pcf_wildcard_key" {
  type = "string"
}

resource "aws_iam_server_certificate" "pcf_wildcard_cert" {
  name_prefix = "${var.env_id}"
  certificate_body = "${var.pcf_wildcard_cert}"
  certificate_chain = "${var.pcf_wildcard_chain}"
  private_key = "${var.pcf_wildcard_key}"
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

output "pcf_wildcard_cert_arn" {
  value = "${aws_iam_server_certificate.pcf_wildcard_cert.arn}"
}
