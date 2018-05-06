resource "aws_iam_role" "bbl" {
  name = "${var.env_id}_bbl_role"
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "bbl" {
  name = "${var.env_id}_bbl_policy"
  path = "/"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
              "logs:*",
              "elasticloadbalancing:*",
              "cloudformation:*",
              "iam:*",
              "kms:*",
              "route53:*",
              "ec2:*"
          ],
          "Resource": "*"
      }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "bbl" {
  role       = "${var.env_id}_bbl_role"
  policy_arn = "${aws_iam_policy.bbl.arn}"
}

resource "aws_iam_user" "bbl" {
  name = "${var.env_id}-bbl"
}

resource "aws_iam_access_key" "bbl" {
  user    = "${aws_iam_user.bbl.name}"
}

output "bbl_iam_user" {
  value = "${aws_iam_user.bbl.name}"
}

output "bbl_secret_access_key_id" {
  value = "${aws_iam_access_key.bbl.id}"
}

output "bbl_secret_access_key" {
  value = "${aws_iam_access_key.bbl.secret}"
}
