# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:564180615104:secret:EOPManagerConfig-m0z3Sp"
  container_image_tag        = "2e9d24c5cea735de32cc7dfbc0b044a590c5df1b"
}
