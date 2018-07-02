variable "vault_host" {
  type = "string"
}

locals {
  vault_fqdn = "${var.vault_host}.${var.subdomain}"
}

resource "aws_route53_record" "vault_dns" {
  zone_id = "${aws_route53_zone.bootstrap_dns_zone.id}"
  name    = "${local.vault_fqdn}"
  type    = "CNAME"
  ttl  = "${var.dns_ttl}"

  records = ["${aws_lb.vault_lb.dns_name}"]
}
