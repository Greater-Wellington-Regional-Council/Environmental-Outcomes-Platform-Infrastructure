# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/data-stores/msk.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

inputs = {
  kafka_version = "3.3.1"
}
