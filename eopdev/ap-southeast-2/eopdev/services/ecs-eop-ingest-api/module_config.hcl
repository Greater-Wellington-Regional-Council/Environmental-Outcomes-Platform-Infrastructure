# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn      = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPIngestAPIConfig-Sd0J4T"
  users_secrets_manager_arn       = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPIngestAPIUsers-OGblpw"
  kafka_creds_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:AmazonMSK_EOPIngestAPIKafkaCredentials-kndW0a"
  container_image_tag             = "d32a5c6e7bda628c2f51a280120568a587b63ea5"
}
