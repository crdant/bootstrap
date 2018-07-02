variable "ldap_port" {
  type = "string"
}

resource "aws_security_group" "ldap_lb_internal_security_group" {
  name        = "${var.env_id}-ldap-lb-internal-security-group"
  description = "Concourse Internal"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "${var.env_id}-ldap-lb-internal-security-group"
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_security_group_rule" "ldap_lb_internal_ldap_port" {
  type        = "ingress"
  protocol    = "tcp"
  from_port   = "${var.ldap_port}"
  to_port     = "${var.ldap_port}"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.ldap_lb_internal_security_group.id}"
}

resource "aws_security_group_rule" "ldap_lb_internal_egress" {
  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.ldap_lb_internal_security_group.id}"
}

resource "aws_lb" "ldap_lb" {
  name               = "${var.short_env_id}-ldap-lb"
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.lb_subnets.*.id}"]
}

resource "aws_lb_listener" "ldap_lb_api_port" {
  load_balancer_arn = "${aws_lb.ldap_lb.arn}"
  protocol          = "TCP"
  port              = "${var.ldap_port}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ldap_lb_api_port.arn}"
  }
}

resource "aws_lb_target_group" "ldap_lb_api_port" {
  name     = "${var.short_env_id}-ldap-port"
  port     = "${var.ldap_port}"
  protocol = "TCP"
  vpc_id   = "${local.vpc_id}"

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 10
    interval            = 30
    protocol            = "TCP"
  }
}

output "ldap_lb_internal_security_group" {
  value = "${aws_security_group.ldap_lb_internal_security_group.name}"
}

output "ldap_lb_target_groups" {
  value = ["${aws_lb_target_group.ldap_lb_api_port.name}"]
}

output "ldap_lb_name" {
  value = "${aws_lb.ldap_lb.name}"
}

output "ldap_lb_url" {
  value = "${aws_lb.ldap_lb.dns_name}"
}
