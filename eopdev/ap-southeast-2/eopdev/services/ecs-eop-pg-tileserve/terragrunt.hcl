include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-eop-pg-tileserve.hcl"
  expose = true
}

locals {
  db_url_sercret_arn = "arn:aws:secretsmanager:ap-southeast-2:657968434173:secret:EOPTileServerConfig-aTHOy7"
  

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
  container_definitions = [
    for name, definition in include.envcommon.inputs._container_definitions_map :
    merge(
      definition,
      {
        name        = name
        image       = local.container_images[name]
        environment = concat(definition.environment)
        secrets = [
          {
            name: "DATABASE_URL",
            valueFrom: "${local.db_url_sercret_arn}:DATABASE_URL::"
          }
        ]
      },
    )
  ]

  secrets_access = [
    local.db_url_sercret_arn,
  ]
}
