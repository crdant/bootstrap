resource "aws_iam_role" "pcf" {
  name = "${var.env_id}_pcf_role"
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

resource "aws_iam_policy" "pcf" {
  name = "${var.env_id}_pcf_policy"
  path = "/"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "PcfInfrastructureCreateIAM",
        "Effect": "Allow",
        "Action": [
            "iam:*"
        ],
        "Resource": [
            "arn:aws:iam::*:user/${var.short_env_id}*",
            "arn:aws:iam::*:user/system/${var.short_env_id}*",
            "arn:aws:iam::*:role/${var.short_env_id}*",
            "arn:aws:iam::*:instance-profile/${var.short_env_id}*",
            "arn:aws:iam::*:policy/${var.short_env_id}*"
        ]
    },
    {
        "Sid": "PcfInfrastructureCreateVpc",
        "Effect": "Allow",
        "Action": [
            "ec2:*Vpc*",
            "ec2:*Subnet*",
            "ec2:*Gateway*",
            "ec2:*Route*",
            "ec2:*Address*",
            "ec2:*SecurityGroup*",
            "ec2:*NetworkAcl*",
            "ec2:*DhcpOptions*"
        ],
        "Resource": "*"
    },
    {
        "Sid": "PcfInfrastructureDNS",
        "Effect": "Allow",
        "Action": [
            "route53:GetHostedZone",
            "route53:ListHostedZones",
            "route53:ChangeResourceRecordSets",
            "route53:ListResourceRecordSets",
            "route53:GetHostedZoneCount",
            "route53:ListHostedZonesByName",
            "route53:GetChange"
        ],
        "Resource": "*"
    },
    {
        "Sid": "PcfInfrastructureRDS",
        "Effect": "Allow",
        "Action": [
            "rds:*"
        ],
        "Resource": "*"
    },
    {
        "Sid": "PcfInfrastructureELB",
        "Effect": "Allow",
        "Action": [
            "elasticloadbalancing:*"
        ],
        "Resource": "*"
    },
    {
        "Sid": "OpsMgrInfrastructureIaasConfiguration",
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeKeypairs",
            "ec2:DescribeVpcs",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAccountAttributes"
        ],
        "Resource": "*"
    },
    {
        "Sid": "OpsMgrInfrastructureDirectorConfiguration",
        "Effect": "Allow",
        "Action": [
            "s3:*"
        ],
        "Resource": [
            "arn:aws:s3:::${var.short_env_id}-bosh",
            "arn:aws:s3:::${var.short_env_id}-bosh/*",
            "arn:aws:s3:::${var.short_env_id}-buildpacks",
            "arn:aws:s3:::${var.short_env_id}-buildpacks/*",
            "arn:aws:s3:::${var.short_env_id}-packages",
            "arn:aws:s3:::${var.short_env_id}-packages/*",
            "arn:aws:s3:::${var.short_env_id}-resources",
            "arn:aws:s3:::${var.short_env_id}-resources/*",
            "arn:aws:s3:::${var.short_env_id}-droplets",
            "arn:aws:s3:::${var.short_env_id}-droplets/*"
        ]
    },
    {
        "Sid": "OpsMgrInfrastructureAvailabilityZones",
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeAvailabilityZones"
        ],
        "Resource": "*"
    },
    {
        "Sid": "OpsMgrInfrastructureNetworks",
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeSubnets"
        ],
        "Resource": "*"
    },
    {
        "Sid": "DeployMicroBosh",
        "Effect": "Allow",
        "Action": [
            "ec2:Describe*",
            "ec2:RunInstances",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:DescribeInstances",
            "ec2:TerminateInstances",
            "ec2:RebootInstances",
            "ec2:ModifyInstanceAttribute",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "ec2:DisassociateAddress",
            "ec2:AssociateAddress",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:AttachVolume",
            "ec2:DeleteVolume",
            "ec2:DetachVolume",
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot"
        ],
        "Resource": "*"
    }
]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "pcf" {
  user       = "${aws_iam_user.pcf.name}"
  policy_arn = "${aws_iam_policy.pcf.arn}"
}

resource "aws_iam_role_policy_attachment" "pcf" {
  role       = "${aws_iam_role.pcf.name}"
  policy_arn = "${aws_iam_policy.pcf.arn}"
}

resource "aws_iam_user" "pcf" {
  name = "${var.env_id}-pcf"
}

resource "aws_iam_access_key" "pcf" {
  user    = "${aws_iam_user.pcf.name}"
}

output "pcf_iam_user" {
  value = "${aws_iam_user.pcf.name}"
}

output "pcf_secret_access_key_id" {
  value = "${aws_iam_access_key.pcf.id}"
}

output "pcf_secret_access_key" {
  value = "${aws_iam_access_key.pcf.secret}"
}
