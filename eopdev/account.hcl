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
}
