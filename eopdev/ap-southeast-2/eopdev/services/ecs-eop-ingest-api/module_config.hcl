# Define some config vars that can be imported by the shared terragrunt config. To keep the config dry.
locals {
  config_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPIngestAPIConfig-Sd0J4T"
  container_image_tag        = "fc39b18935476c1961501233f302defaedabb4a5"
}
