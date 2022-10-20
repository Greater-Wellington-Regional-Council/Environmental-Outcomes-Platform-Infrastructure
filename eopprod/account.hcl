# Set account-wide variables
locals {
  account_name = "eopprod"
  account_role = "prod"
  domain_name = {
    name = "gw-eop-prod.tech"
    properties = {
      created_outside_terraform = true
    }
  }
}
