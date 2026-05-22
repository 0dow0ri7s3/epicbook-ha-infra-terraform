output "ecr_repository_url" {
  description = "The URL of the ECR repository for the application pipeline"
  value       = module.compute.ecr_url
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "The public URL of the application load balancer"
}