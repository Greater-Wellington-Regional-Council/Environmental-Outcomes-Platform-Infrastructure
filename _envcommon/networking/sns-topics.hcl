# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for networking/sns-topics. The common variables for each environment to
# deploy networking/sns-topics are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.107.5"
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies are modules that need to be deployed before this one.
# ---------------------------------------------------------------------------------------------------------------------

dependency "account_baseline" {
  config_path = "${dirname(find_in_parent_folders("account.hcl"))}/_global/account-baseline"

  mock_outputs = {
    kms_key_arns = {
      (local.aws_region) = {
        "cloudwatch-alarm-sns-encryption" = "arn:aws:kms:us-east-1:111122223333:key/asdf"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/networking/sns-topics"

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name and account_role for easy access
  account_name = local.account_vars.locals.account_name
  account_role = local.account_vars.locals.account_role

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name = "${local.name_prefix}-${lower(local.account_name)}-cloudwatch-alarms"
  allow_publish_services = [
    "events.amazonaws.com",
    "cloudwatch.amazonaws.com",
  ]

  kms_master_key_id = dependency.account_baseline.outputs.kms_key_arns[local.aws_region]["cloudwatch-alarm-sns-encryption"]
}
