terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.96.9"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-eop-pg-tileserve.hcl"
  expose = true
}

locals {
  # TODO: Is this needed?
  tls_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:SampleAppBackEndCA-yT4JVB"
  db_url_sercret_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:RDSDBConfig-wHo5DD"

  # List of environment variables and container images for each container that are specific to this environment. The map
  # key here should correspond to the map keys of the _container_definitions_map input defined in envcommon.
  service_environment_variables = {
    (include.envcommon.locals.service_name) = [
      {
        name  = "CONFIG_SECRETS_SECRETS_MANAGER_TLS_ID"
        value = local.tls_secrets_manager_arn
      },
    ]
  }
  container_images = {
    (include.envcommon.locals.service_name) = "${include.envcommon.locals.container_image}:${local.tag}"
  }

  # Specify the app image tag here so that it can be overridden in a CI/CD pipeline.
  tag = "20221019"
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # The Container definitions of the ECS service. The following environment specific parameters are injected into the
  # common definition defined in the envcommon config:
  # - Image tag
  # - Secrets manager ARNs
  container_definitions = [
    for name, definition in include.envcommon.inputs._container_definitions_map :
    merge(
      definition,
      {
        name        = name
        image       = local.container_images[name]
        secrets = [
          {
            name: "DATABASE_URL",
            valueFrom: local.db_url_sercret_arn
          }
        ]
        environment = concat(definition.environment, local.service_environment_variables[name])
      },
    )
  ]

  # TODO: Does this add permissions for the service to read the secret?
  secrets_access = [
    local.tls_secrets_manager_arn,
    local.db_url_sercret_arn,
  ]
}
