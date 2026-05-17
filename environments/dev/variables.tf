variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources into"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "The deployment environment name"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "List of private app subnet CIDRs"
}

variable "private_data_subnet_cidrs" {
  type        = list(string)
  description = "List of private data subnet CIDRs"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of target availability zones"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "The master password for the RDS database instance"
}

variable "app_port" {
  type        = number
  description = "The port the application listens on"
}