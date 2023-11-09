terraform {
  source = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-load-balancer.git//modules/acm-tls-certificate?ref=v0.29.18"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  acm_tls_certificates = {
    "${local.account_vars.locals.domain_name.name}" = {
      tags = {
        run_destroy_check = true
      }
      subject_alternative_names  = ["*.${local.account_vars.locals.domain_name.name}"]
      create_verification_record = true
      verify_certificate         = true
    }
  }
}
