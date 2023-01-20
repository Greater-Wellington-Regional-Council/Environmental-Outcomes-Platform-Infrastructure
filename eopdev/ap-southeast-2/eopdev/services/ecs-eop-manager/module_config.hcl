# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPManagerConfig-cWXx3Q"
  container_image_tag        = "9cd31e470fa1b8576f9f22d8127d5fced42cee83"
}
