# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/data-stores/aurora.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name = "aurora-eopdev"

  # The DB config secret contains the following data:
  # - DB engine (e.g. postgres, mysql, etc)
  # - Default database name
  # - Port
  # - Username and password
  # Alternatively, these can be specified as individual inputs.
  db_config_secrets_manager_id = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:RDSDBConfig-wHo5DD"
}
