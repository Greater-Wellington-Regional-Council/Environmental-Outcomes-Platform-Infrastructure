output "ingest_api_kafka_credentials_arn" {
  description = "The ARN for the ingest API Kafka Credentials secret"
  value       = aws_secretsmanager_secret.ingest_api_kafka_credentials.arn
}

output "ingest_api_config_arn" {
  description = "The ARN for the ingest API Config secret"
  value       = aws_secretsmanager_secret.ingest_api_config.arn
}

output "ingest_api_users_arn" {
  description = "The ARN for the ingest API users secret"
  value       = aws_secretsmanager_secret.ingest_api_users.arn
}
