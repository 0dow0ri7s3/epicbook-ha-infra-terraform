# Create DB Subnet Group linking the two private data subnets
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  subnet_ids  = var.private_data_subnet_ids
  description = "Database subnet group spanning multiple AZs"

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# Provision the Multi-AZ MySQL Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-epicbook-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small" # Supports Multi-AZ workloads efficiently
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  multi_az               = true
  skip_final_snapshot    = true

  tags = {
    Name = "${var.environment}-rds-mysql"
  }
}