variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where security groups will be created"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "app_port" {
  type        = number
  description = "The port the application listens on"
}