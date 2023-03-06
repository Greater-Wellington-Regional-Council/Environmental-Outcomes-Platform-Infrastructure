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
}
