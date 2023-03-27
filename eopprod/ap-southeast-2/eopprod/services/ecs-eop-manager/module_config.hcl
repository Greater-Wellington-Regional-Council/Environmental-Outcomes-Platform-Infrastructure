# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:422253851608:secret:EOPManagerConfig-NU6YXY"
  container_image_tag        = "90d4e9a5ff0f92bc2965b84d297ae82f923b9432"
}
