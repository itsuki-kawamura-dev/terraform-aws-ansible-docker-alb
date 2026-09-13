resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id]
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id]
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id]
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

}