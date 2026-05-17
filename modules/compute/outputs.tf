output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The public URL of the application load balancer"
}