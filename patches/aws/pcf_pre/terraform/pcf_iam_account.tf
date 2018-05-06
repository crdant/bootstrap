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
        "Effect": "Deny",
        "Action": [
            "iam:*"
        ],
        "Resource": [
            "*"
        ]
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
            "arn:aws:s3:::pcf-ops-manager-bucket",
            "arn:aws:s3:::pcf-ops-manager-bucket/*",
            "arn:aws:s3:::pcf-buildpacks-bucket",
            "arn:aws:s3:::pcf-buildpacks-bucket/*",
            "arn:aws:s3:::pcf-packages-bucket",
            "arn:aws:s3:::pcf-packages-bucket/*",
            "arn:aws:s3:::pcf-resources-bucket",
            "arn:aws:s3:::pcf-resources-bucket/*",
            "arn:aws:s3:::pcf-droplets-bucket",
            "arn:aws:s3:::pcf-droplets-bucket/*"
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
            "ec2:DescribeImages",
            "ec2:RunInstances",
            "ec2:DescribeInstances",
            "ec2:TerminateInstances",
            "ec2:RebootInstances",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "ec2:DescribeAddresses",
            "ec2:DisassociateAddress",
            "ec2:AssociateAddress",
            "ec2:CreateTags",
            "ec2:DescribeVolumes",
            "ec2:CreateVolume",
            "ec2:AttachVolume",
            "ec2:DeleteVolume",
            "ec2:DetachVolume",
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot",
            "ec2:DescribeSnapshots",
            "ec2:DescribeRegions"
        ],
        "Resource": "*"
    }
]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "pcf" {
  role       = "${var.env_id}_pcf_role"
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
