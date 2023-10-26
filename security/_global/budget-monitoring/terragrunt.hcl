include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/landingzone/budget-monitoring.hcl"
}

inputs = {
  total_monthly_budget_amount      = 75
  monthly_cloudwatch_budget_amount = 5
}
