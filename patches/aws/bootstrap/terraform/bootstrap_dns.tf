variable "bootstrap_domain" {
  type = "string"
}

resource "aws_route53_zone" "bootstrap_dns_zone" {
  name = "${var.bootstrap_domain}"

  tags {
    Name = "${var.env_id}-bootstrap-zone"
  }
}
