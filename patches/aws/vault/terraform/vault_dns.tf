variable "vault_host" {
  type = "string"
}

resource "aws_route53_record" "vault_dns" {
  zone_id = "${aws_route53_zone.bootstrap_dns_zone.id}"
  name    = "${var.vault_host}"
  type    = "CNAME"
  ttl  = "${var.dns_ttl}"

  records = ["${aws_lb.vault_lb.dns_name}"]
}
