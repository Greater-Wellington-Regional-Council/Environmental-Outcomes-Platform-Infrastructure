
# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.69.3"
}
# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-security.git//modules/secrets-manager-resource-policies"

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
  # A local for more convenient access to the accounts map.
  account_ids       = local.common_vars.locals.account_ids
  accounts_to_share = [for name, id in local.account_ids : "arn:aws:iam::${id}:root" if name != "shared"]
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  secret_policies = {
    GitHubPAT = {
      arn                           = "arn:aws:secretsmanager:ap-southeast-2:898449181946:secret:MachineUserGitHubPAT-w1bDpA"
      iam_entities_with_read_access = local.accounts_to_share
      iam_entities_with_full_access = []
      policy_statement_json         = ""
    }
    VCSPAT = {
      arn                           = "arn:aws:secretsmanager:ap-southeast-2:898449181946:secret:MachineUserGitHubPAT-w1bDpA"
      iam_entities_with_read_access = local.accounts_to_share
      iam_entities_with_full_access = []
      policy_statement_json         = ""
    }
  }
}
