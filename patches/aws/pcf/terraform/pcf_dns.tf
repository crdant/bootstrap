variable "pcf_subdomain" {
  type = "string"
}

variable "opsman_host" {
  type = "string"
}

locals {
  default_opsman_dns_name = "opsman.${var.pcf_subdomain}"
}

resource "aws_route53_zone" "pcf_dns_zone" {
  name = "${var.pcf_subdomain}"

  tags {
    Name = "${var.env_id}-pcf-zone"
  }
}

resource "aws_route53_record" "pcf_delgation_dns" {
  zone_id = "${aws_route53_zone.bootstrap_dns_zone.id}"
  name    = "${var.pcf_subdomain}"
  type    = "NS"
  ttl     = 300

  records = ["${aws_route53_zone.pcf_dns_zone.name_servers}"]
}

resource "aws_route53_record" "opsman" {
  zone_id = "${aws_route53_zone.pcf_dns_zone.id}"
  name    = "${var.opsman_host}"
  type    = "CNAME"
  ttl     = 300

  records = ["${local.default_opsman_dns_name}"]
}

output "pcf_dns_zone_id" {
  value = "${aws_route53_zone.pcf_dns_zone.id}"
}
