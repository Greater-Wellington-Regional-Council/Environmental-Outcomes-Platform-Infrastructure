# Set account-wide variables
locals {
  account_name = "eopdev"
  account_role = "dev"
  domain_name = {
    name = "gw-eop-dev.tech"
    properties = {
      created_outside_terraform = true
    }
  }

  budget_monitoring_notification_email_addresses = ["eop+eopdev_budget_notifications@gw.govt.nz"]
}
