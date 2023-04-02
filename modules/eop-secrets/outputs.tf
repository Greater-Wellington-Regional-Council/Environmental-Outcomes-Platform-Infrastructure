# Aurora Postgres
output "aurora_rds_config_arn" {
  description = "The ARN for the ingest Aurora RDS Config secret"
  value       = aws_secretsmanager_secret.aurora_rds_config.arn
}

# Manager
output "manager_config_arn" {
  description = "The ARN for the Manager Config secret"
  value       = aws_secretsmanager_secret.manager_config.arn
}

# Tile Server
output "tileserver_config_arn" {
  description = "The ARN for the Tileserver Config secret"
  value       = aws_secretsmanager_secret.tileserver_config.arn
}

# Kafka
output "kafka_client_credentials_arn" {
  description = "The ARN for the Kafka Credentials secret"
  value       = aws_secretsmanager_secret.kafka_client_credentials.arn
}

# Ingest API
output "ingest_api_config_arn" {
  description = "The ARN for the Ingest API Config secret"
  value       = aws_secretsmanager_secret.ingest_api_config.arn
}

output "ingest_api_users_arn" {
  description = "The ARN for the Ingest API users secret"
  value       = aws_secretsmanager_secret.ingest_api_users.arn
}
