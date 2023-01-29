# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.96.9"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/networking/route53-public.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

inputs = {
  public_zones = {
    "gw-eop-prod.tech" = {
      comment       = ""
      tags          = {}
      force_destroy = false
      base_domain_name_tags = {
      }
      created_outside_terraform = true
      subject_alternative_names = ["*.gw-eop-prod.tech"]
      hosted_zone_domain_name   = "gw-eop-prod.tech"
    },
    "eop.gw.govt.nz" = {
      comment       = ""
      tags          = {}
      force_destroy = false
      base_domain_name_tags = {
      }
      created_outside_terraform = true
      subject_alternative_names = ["*.eop.gw.govt.nz"]
      hosted_zone_domain_name   = "eop.gw.govt.nz"
    }
  }
}
