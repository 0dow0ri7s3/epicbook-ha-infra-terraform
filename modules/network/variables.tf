variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the 2 public subnets"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the 2 private app subnets"
}

variable "private_data_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the 2 private data subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "The list of AZs to deploy into"
}