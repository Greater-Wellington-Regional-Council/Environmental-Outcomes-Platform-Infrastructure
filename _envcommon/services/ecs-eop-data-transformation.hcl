
dependency "eop_secrets" {
  config_path = "${get_terragrunt_dir()}/../../secrets"
  mock_outputs = {
    ingest_api_kafka_credentials_arn = "secret_arn"
    ingest_api_config_arn            = "secret_arn"
    ingest_api_users_arn             = "secret_arn"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "aurora" {
  config_path = "${get_terragrunt_dir()}/../../data-stores/aurora"

  mock_outputs = {
    primary_endpoint = "rds"
    port             = 5432
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "ecs_fargate_cluster" {
  config_path = "${get_terragrunt_dir()}/../ecs-fargate-cluster"

  mock_outputs = {
    ecs_cluster_arn  = "some-ecs-cluster-arn"
    ecs_cluster_name = "ecs-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../networking/vpc"

  mock_outputs = {
    vpc_id = "vpc-abcd1234"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name for easy access
  account_name = local.account_vars.locals.account_name

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region

  service_name    = "eop-data-transformation"
  container_image = "898449181946.dkr.ecr.ap-southeast-2.amazonaws.com/eop-data-transformation"

  module_config       = read_terragrunt_config("module_config.hcl")
  container_image_tag = local.module_config.locals.container_image_tag
}

terraform {
  source = "../../../../..//modules/scheduled-task"
}

inputs = {
  service_name             = local.service_name
  ecs_target_cluster_arn   = dependency.ecs_fargate_cluster.outputs.arn
  task_schedule_expression = "cron(0 * * * ? *)"

  account_name = local.account_name
  aws_region   = local.aws_region

  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.private_app_subnet_ids

  container_definitions = [
    {
      name      = "${local.service_name}"
      image     = "${local.container_image}:${local.container_image_tag}"
      essential = true
      environment = [
        {
          name  = "CONFIG_DATABASE_HOST"
          value = dependency.aurora.outputs.primary_endpoint
        },
      ]
      secrets = [
        {
          name : "CONFIG_DATABASE_USERNAME",
          valueFrom : "${dependency.eop_secrets.outputs.data_transformation_config_arn}:CONFIG_DATABASE_USERNAME::"
        },
        {
          name : "CONFIG_DATABASE_PASSWORD",
          valueFrom : "${dependency.eop_secrets.outputs.data_transformation_config_arn}:CONFIG_DATABASE_PASSWORD::"
        },
        {
          name : "CONFIG_DATABASE_NAME",
          valueFrom : "${dependency.eop_secrets.outputs.data_transformation_config_arn}:CONFIG_DATABASE_NAME::"
        },
      ]

      # Configure log aggregation from the ECS service to stream to CloudWatch logs.
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/${local.account_name}/ecs/${local.service_name}"
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ]

  secrets_manager_arns = [
    dependency.eop_secrets.outputs.data_transformation_config_arn,
  ]
}
