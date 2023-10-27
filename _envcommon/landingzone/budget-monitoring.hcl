terraform {
  source = "../../..//modules/budget-monitoring"
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  total_monthly_budget_amount      = 1250.00
  monthly_cloudwatch_budget_amount = 150

  notification_email_addresses = setunion(local.account_vars.locals.budget_monitoring_notification_email_addresses, local.common_vars.locals.budget_monitoring_notification_email_addresses)
}
