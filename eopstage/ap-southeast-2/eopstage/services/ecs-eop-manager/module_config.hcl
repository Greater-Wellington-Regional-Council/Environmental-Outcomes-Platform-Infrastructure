# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:564180615104:secret:EOPManagerConfig-m0z3Sp"
  container_image_tag        = "d32a5c6e7bda628c2f51a280120568a587b63ea5"
}
