variable "ldap_host" {
  type = "string"
}

resource "aws_route53_record" "ldap_dns" {
  zone_id = "${aws_route53_zone.bootstrap_dns_zone.id}"
  name    = "${var.ldap_host}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_lb.ldap_lb.dns_name}"]
}
