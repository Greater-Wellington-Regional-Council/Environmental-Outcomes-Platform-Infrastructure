terraform {
  source = "../../..//modules/budget-monitoring"
}

dependency "account_baseline" {
  config_path = "${dirname(find_in_parent_folders("account.hcl"))}/_global/account-baseline"

  mock_outputs = {
    kms_key_arns = {
      (local.aws_region) = {
        "budget-alarm-sns-encryption" = "arn:aws:kms:us-east-1:111122223333:key/asdf"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name and account_role for easy access
  account_name = local.account_vars.locals.account_name

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region
}

inputs = {
  total_monthly_budget_amount      = 1250.00
  monthly_cloudwatch_budget_amount = 150

  sns_topic_name        = "${local.name_prefix}-${lower(local.account_name)}-budget-alarms"
  sns_kms_master_key_id = dependency.account_baseline.outputs.kms_key_arns[local.aws_region]["budget-alarm-sns-encryption"]

}
