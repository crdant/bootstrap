resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.PcfVpc.id}"
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.cloud_controller.id}",
    "${aws_security_group.directorSG.id}"
  ]

  subnet_ids = [
    "${aws_subnet.PcfVpcDynamicServicesSubnet_az1}",
    "${aws_subnet.PcfVpcDynamicServicesSubnet_az2",
    "${aws_subnet.PcfVpcDynamicServicesSubnet_az3",
    "${aws_subnet.PcfVpcErtSubnet_az1",
    "${aws_subnet.PcfVpcErtSubnet_az2",
    "${aws_subnet.PcfVpcErtSubnet_az3",
    "${aws_subnet.PcfVpcInfraSubnet_az1",
    "${aws_subnet.PcfVpcPublicSubnet_az1",
    "${aws_subnet.PcfVpcPublicSubnet_az2",
    "${aws_subnet.PcfVpcPublicSubnet_az3",
    "${aws_subnet.PcfVpcServicesSubnet_az1",
    "${aws_subnet.PcfVpcServicesSubnet_az2",
    "${aws_subnet.PcfVpcServicesSubnet_az3"
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id             = "${aws_vpc.PcfVpc.id}"
  service_name       = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = [
      "${aws_route_table.PublicSubnetRouteTable.id}",
      "${aws_route_table.PrivateSubnetRouteTable_az1.id}",
      "${aws_route_table.SubnetRouteTable_az2.id}",
      "${aws_route_table.SubnetRouteTable_az3.id}"
    ]
}
