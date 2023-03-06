# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPManagerConfig-cWXx3Q"
  container_image_tag        = "dc83ca1882c26e8af5991b750d6f5a788614f80a"
}
