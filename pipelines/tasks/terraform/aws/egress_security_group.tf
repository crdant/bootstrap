
variable "github_ips" {
  type = "list"
}

variable "ec2_ips" {
  type = "list"
}

variable "cloudfront_ips" {
  type = "list"
}

resource "aws_security_group" "pivotal_egress" {
  name        = "pivotal-egress-security-group"
  description = "Allow egress for Concourse, BOSH director, and Pivotal Cloud Foundry"
  vpc_id      = "${aws_vpc.PcfVpc.id}"

  tags {
    Name = "pivotal-egress-security-group"
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_security_group_rule" "egress_for_ec2" {
  type        = "egress"
  protocol    = "tcp"
  from_port   = "443"
  to_port     = "443"
  cidr_blocks = [ "${var.ec2_ips}" ]

  security_group_id = "${aws_security_group.pivotal_egress.id}"
}

resource "aws_security_group_rule" "egress_for_cloudfront" {
  type        = "egress"
  protocol    = "tcp"
  from_port   = "443"
  to_port     = "443"
  cidr_blocks = [ "${var.cloudfront_ips}" ]

  security_group_id = "${aws_security_group.pivotal_egress.id}"
}

resource "aws_security_group_rule" "egress_for_github" {
  type        = "egress"
  protocol    = "tcp"
  from_port   = "443"
  to_port     = "443"
  cidr_blocks = [ "${var.github_ips}" ]

  security_group_id = "${aws_security_group.pivotal_egress.id}"
}


output "pivotal_egress" {
  value = "${aws_security_group.pivotal_egress.name}"
}
