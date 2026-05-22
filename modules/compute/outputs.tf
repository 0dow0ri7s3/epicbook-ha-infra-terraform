output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The public URL of the application load balancer"
}

output "alb_arn" {
  value       = aws_lb.main.arn
  description = "The ARN of the application load balancer"
}

output "ecr_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url  # Or whatever your ECR resource block name is
}