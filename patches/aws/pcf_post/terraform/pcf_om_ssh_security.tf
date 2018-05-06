resource "aws_security_group" "om_ssh_internal_security_group" {
  name        = "${var.env_id}-om-ssh-internal-security-group"
  description = "Ops Manager SSH"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "${var.env_id}-om-ssh-internal-security-group"
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_security_group_rule" "om_ssh_internal_vault_port" {
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.om_ssh_internal_security_group.id}"
}
