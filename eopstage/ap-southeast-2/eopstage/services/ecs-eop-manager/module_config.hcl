# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:564180615104:secret:EOPManagerConfig-m0z3Sp"
  container_image_tag        = "c75a762464dc0b4484b55f02cae61cd956d6ebb3"
}
