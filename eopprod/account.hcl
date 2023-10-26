# Set account-wide variables
locals {
  account_name = "eopprod"
  account_role = "prod"
  domain_name = {
    name = "eop.gw.govt.nz"
    properties = {
      created_outside_terraform = true
    }
  }
  budget_monitoring_notification_email_addresses = ["eop+eopprod_budget_notifications@gw.govt.nz"]
}
