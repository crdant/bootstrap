resource "aws_security_group_rule" "pcf_internal_egress_only" {
  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [ "${var.vpc_cidr}" ]

  security_group_id = "${aws_security_group.pcfSG.id}"
}
