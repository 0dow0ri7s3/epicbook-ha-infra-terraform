output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "The connection endpoint for the database"
}

output "db_address" {
  value       = aws_db_instance.main.address
  description = "The database hostname address"
}