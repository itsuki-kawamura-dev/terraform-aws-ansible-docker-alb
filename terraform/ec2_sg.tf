resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2"
  vpc_id      = aws_vpc.main_vpc.id

  # inbound rule intentionally empty

  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ec2_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "ssm_endpoint" {
  name        = "ssm-sg"
  description = "Security group for SSM"
  vpc_id      = aws_vpc.main_vpc.id

  # inbound rule intentionally empty

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
