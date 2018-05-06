variable "pcf_subdomain" {
  type = "string"
}

resource "aws_acm_certificate" "cert" {
  domain_name = "${var.pcf_subdomain}"
  validation_method = "NONE"
}

output "pcf_wildcard_cert_arn" {
  value = "${aws_acm_certificate.cert.arn}"
}
