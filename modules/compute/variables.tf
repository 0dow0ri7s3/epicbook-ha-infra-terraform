variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "private_app_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the ASG instances"
}

variable "alb_sg_id" {
  type        = string
  description = "Security group ID for the ALB"
}

variable "app_sg_id" {
  type        = string
  description = "Security group ID for the App instances"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type for the application"
}

variable "app_port" {
  type        = number
  description = "The port the application listens on"
}