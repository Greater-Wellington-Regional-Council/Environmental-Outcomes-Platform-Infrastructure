# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:422253851608:secret:EOPTileServerConfig-56JaUG"
  container_image_tag        = "20221019"
}
