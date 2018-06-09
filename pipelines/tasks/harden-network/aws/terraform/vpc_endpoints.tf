resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.PcfVpc.id}"
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id             = "${aws_vpc.PcfVpc.id}"
  service_name       = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type  = "Gateway"

  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]

  policy = <<POLICY
{
"Statement": [
  {
    "Sid": "Access-to-blobstore-buckets-only",
    "Principal": "*",
    "Action": [
      "s3:::*"
    ],
    "Effect": "Allow",
    "Resource": [ "arn:aws:s3:::${aws_s3_bucket.bosh.bucket},
                  "arn:aws:s3:::${aws_s3_bucket.bosh.bucket}/*",
                  "arn:aws:s3:::${aws_s3_bucket.buildpacks.bucket},
                  "arn:aws:s3:::${aws_s3_bucket.buildpacks.bucket}/*",
                  "arn:aws:s3:::${aws_s3_bucket.droplets.bucket},
                  "arn:aws:s3:::${aws_s3_bucket.droplets.bucket}/*",
                  "arn:aws:s3:::${aws_s3_bucket.packages.bucket},
                  "arn:aws:s3:::${aws_s3_bucket.packages.bucket}/*",
                  "arn:aws:s3:::${aws_s3_bucket.resources.bucket},
                  "arn:aws:s3:::${aws_s3_bucket.resources.bucket}/*" ]
  }
]
}
POLICY
}
