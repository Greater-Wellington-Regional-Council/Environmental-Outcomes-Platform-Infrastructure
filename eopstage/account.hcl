# Set account-wide variables
locals {
  account_name = "eopstage"
  account_role = "stage"
  domain_name = {
    name = "gw-eop-stage.tech"
    properties = {
      created_outside_terraform = true
    }
  }
  budget_monitoring_notification_email_addresses = ["eop+eopstage_budget_notifications@gw.govt.nz"]
}
