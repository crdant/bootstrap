variable "concourse_host" {
  type = "string"
}

resource "aws_route53_record" "concourse_dns" {
  zone_id = "${aws_route53_zone.bootstrap_dns_zone.id}"
  name    = "${var.concourse_host}"
  type    = "CNAME"
  ttl     = "${var.dns_ttl}"

  records = ["${aws_lb.concourse_lb.dns_name}"]
}
