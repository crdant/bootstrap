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

output "pcf_dns_zone_id" {
  value = "${aws_route53_zone.pcf_dns_zone.id}"
}
