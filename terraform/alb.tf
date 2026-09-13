resource "aws_lb" "main" {
  name               = "project4-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_c.id
  ]
}
###### ALB LISTENER ##########
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

###### ALB TARGET ##########
resource "aws_lb_target_group" "app" {
  name     = "project4-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.main.id
  port             = 80
}

########### ALB OUTPUT ###########
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}
