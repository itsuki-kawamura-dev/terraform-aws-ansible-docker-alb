########### ALB OUTPUT ###########
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

########### ALB OUTPUT ###########
output "ec2_instance_id" {
  description = "EC2 instance id"
  value       = aws_instance.main.id
}
