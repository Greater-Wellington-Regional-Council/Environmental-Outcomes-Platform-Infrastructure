terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.96.9"
}

dependency "alb-eop-manager" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb-eop-manager"

  mock_outputs = {
    alb_security_group_id = "sg-abcd1234"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "alb" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb"

  mock_outputs = {
    alb_security_group_id = "sg-abcd1234"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-cluster.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  public_alb_sg_ids   = [dependency.alb.outputs.alb_security_group_id, dependency.alb-eop-manager.outputs.alb_security_group_id]
}