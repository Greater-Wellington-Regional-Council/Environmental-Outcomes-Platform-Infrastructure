# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:564180615104:secret:EOPManagerConfig-m0z3Sp"
  container_image_tag        = "e4571efc2b4ddd6fca99e0622ad52d850ac61939"
}
