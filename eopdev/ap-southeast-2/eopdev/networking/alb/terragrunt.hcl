# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.95.0"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/networking/alb-public.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  alb_name = "gwrc-sample-pub-eopdev"
}