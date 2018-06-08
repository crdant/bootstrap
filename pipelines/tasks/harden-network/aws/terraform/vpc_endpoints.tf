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

  policy             = "${aws_iam_policy.blobstore_access}"
  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]
}

resource "aws_iam_policy" "blobstore_access" {
  name = "${var.env_id}_bbl_policy"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Sid": "Access-to-specific-bucket-only",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [ "arn:aws:s3:::${aws_s3_bucket.bosh.bucket},
                    "arn:aws:s3:::${aws_s3_bucket.bosh.bucket}/*",
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.bucket},
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.bucket}/*",
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.droplets},
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.droplets}/*",
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.packages},
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.packages}/*",
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.resources},
                    "arn:aws:s3:::${aws_s3_bucket.buildpacks.resources}/*" ]
    }
  ]
}
POLICY
}
