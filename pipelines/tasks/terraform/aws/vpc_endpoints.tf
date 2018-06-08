resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.PcfVpc.id}"
  service_name      = "com.amazonaws.${provider.aws.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "${aws_vpc.PcfVpc.id}"
  service_name      = "com.amazonaws.${provider.aws.region}.s3"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]
}
