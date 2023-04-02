data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Aurora Postgres
resource "aws_secretsmanager_secret" "aurora_rds_config" {
  name        = "RDSDBConfig"
  description = "Configuration for the RDS database instance."
}

# Kafka
## SASL config secrets for Kafka require a KMS key that is not the default
resource "aws_kms_key" "kafka_sasl_credentials_key" {
  description = "Used to encrypt Secrets Manager Secrets containing Kafka SASL/SCRAM credentials"
}

resource "aws_kms_alias" "kafka_sasl_credentials_key_alias" {
  target_key_id = aws_kms_key.kafka_sasl_credentials_key.key_id
  name          = "alias/eop-secretsmanager-kafka-sasl-creds"
}

resource "aws_kms_key_policy" "kafka_sasl_credentials_key_policy" {
  key_id = aws_kms_key.kafka_sasl_credentials_key.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Action   = "kms:*"
        Effect   = "Allow"
      },
      {
        Sid = "Allow access through AWS Secrets Manager for all principals in the account that are authorized to use AWS Secrets Manager"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.id
            "kms:ViaService"    = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
        Resource = "*"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
      },
      {
        Sid = "Allow access through AWS Secrets Manager for all principals in the account that are authorized to use AWS Secrets Manager"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.id
          }
          StringLike = {
            "kms:ViaService" = "secretsmanager.*.amazonaws.com"
          }
        }
        Resource = "*"
        Action   = "kms:GenerateDataKey*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "kafka_client_credentials" {
  name        = "AmazonMSK_KafkaClientCredentials"
  description = "SASL/SCRAM Credentials used by the client applications to connect to Kafka"
  kms_key_id  = aws_kms_key.kafka_sasl_credentials_key.id
}

# EOP Manager
resource "aws_secretsmanager_secret" "manager_config" {
  name        = "EOPManagerConfig"
  description = "Sensitive configuration details for the Manager Application"
}

# Tile Server
resource "aws_secretsmanager_secret" "tileserver_config" {
  name        = "EOPTileServerConfig"
  description = "Sensitive configuration details for the TileServer service"
}

# Ingest API
resource "aws_secretsmanager_secret" "ingest_api_config" {
  name        = "EOPIngestAPIConfig"
  description = "Sensitive configuration details for the Ingest API application"
}

resource "aws_secretsmanager_secret" "ingest_api_users" {
  name        = "EOPIngestAPIUsers"
  description = "API users that can access the Ingest API"
}
