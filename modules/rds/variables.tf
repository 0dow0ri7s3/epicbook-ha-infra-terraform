variable "private_data_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the DB subnet group"
}

variable "rds_sg_id" {
  type        = string
  description = "The security group ID for the database"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "db_name" {
  type        = string
  default     = "epicbookdb"
  description = "The name of the database to create"
}

variable "db_username" {
  type        = string
  default     = "epicbook_admin"
  description = "Username for the master DB user"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for the master DB user"
}