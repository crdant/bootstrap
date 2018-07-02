variable "bootstrap_domain" {
  type = "string"
}

locals {
  cloud_subdomain = "aws.${var.domain}"
}

data "aws_route53_zone" "cloud" {
  name = "${local.cloud_subdomain}"
}

resource "aws_route53_zone" "bootstrap_dns_zone" {
  name = "${var.bootstrap_domain}"

  tags {
    Name = "${var.env_id}-bootstrap-zone"
  }
}

resource "aws_route53_record" "bootstrap_delgation_dns" {
  zone_id = "${data.aws_route53_zone.cloud.id}"
  name    = "${var.bootstrap_domain}"
  type    = "NS"
  ttl     = 300

  records = ["${aws_route53_zone.bootstrap_dns_zone.name_servers}"]
}

output "bootstrap_dns_zone_id" {
  value = "${aws_route53_zone.bootstrap_dns_zone.id}"
}
