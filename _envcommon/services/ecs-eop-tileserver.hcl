terraform {
  source = "${local.source_base_url}?ref=v0.107.5"
}

dependency "eop_secrets" {
  config_path = "${get_terragrunt_dir()}/../../secrets"
  mock_outputs = {
    ingest_api_kafka_credentials_arn = "secret_arn"
    ingest_api_config_arn            = "secret_arn"
    ingest_api_users_arn             = "secret_arn"
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

dependency "ecs_fargate_cluster" {
  config_path = "${get_terragrunt_dir()}/../ecs-fargate-cluster"

  mock_outputs = {
    ecs_cluster_arn  = "some-ecs-cluster-arn"
    ecs_cluster_name = "ecs-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "network_bastion" {
  config_path = "${get_terragrunt_dir()}/../../../mgmt/bastion-host"

  mock_outputs = {
    security_group_id = "sg-abcd1234"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "sns" {
  config_path = "${get_terragrunt_dir()}/../../../_regional/sns-topic"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-1:123456789012:mytopic-NZJ5JSMVGFIE"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "alb" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb-eop-manager"

  mock_outputs = {
    listener_arns = {
      80  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/mock-alb/50dc6c495c0c9188/f2f7dc8efc522ab2"
      443 = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/mock-alb/50dc6c495c0c9188/f2f7dc8efc522ab2"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "shared_secret" {
  config_path = "${get_terragrunt_dir()}/../ecs-eop-tileserver-secret"
  mock_outputs = {
    secret = "secret"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/services/ecs-service"

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name for easy access
  account_name = local.account_vars.locals.account_name

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region

  service_name = "eop-tileserver"

  # Define the container image. This will be used in the child config to combine with the specific image tag for the
  # environment.
  container_image = "pramsey/pg_tileserv"

  module_config       = read_terragrunt_config("module_config.hcl")
  container_image_tag = local.module_config.locals.container_image_tag
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # -------------------------------------------------------------------------------------------------------------------
  # Cluster and container configuration
  # -------------------------------------------------------------------------------------------------------------------

  service_name     = local.service_name
  ecs_cluster_name = dependency.ecs_fargate_cluster.outputs.name
  ecs_cluster_arn  = dependency.ecs_fargate_cluster.outputs.arn

  launch_type = "FARGATE"
  task_cpu    = 1024
  task_memory = 2048

  network_mode = "awsvpc"
  network_configuration = {
    vpc_id  = dependency.vpc.outputs.vpc_id
    subnets = dependency.vpc.outputs.private_app_subnet_ids

    security_group_rules = {
      AllowAllEgress = {
        type                     = "egress"
        from_port                = 0
        to_port                  = 0
        protocol                 = "-1"
        cidr_blocks              = ["0.0.0.0/0"]
        source_security_group_id = null
      }
      AllowALBIngress = {
        type                     = "ingress"
        from_port                = 7800
        to_port                  = 7800
        protocol                 = "TCP"
        cidr_blocks              = null
        source_security_group_id = dependency.alb.outputs.alb_security_group_id
      }
      AllowBastionIngress = {
        type                     = "ingress"
        from_port                = 7800
        to_port                  = 7800
        protocol                 = "TCP"
        cidr_blocks              = null
        source_security_group_id = dependency.network_bastion.outputs.bastion_host_security_group_id
      }
    }
    additional_security_group_ids = []
    assign_public_ip              = false
  }

  use_auto_scaling = false

  custom_iam_policy_prefix = local.service_name

  # --------------------------------------------------------------------------------------------------------------------
  # ALB configuration
  # We configure Target Groups for the ECS service so that the ALBs can route to the ECS tasks that are deployed on each
  # node by the service.
  # --------------------------------------------------------------------------------------------------------------------

  elb_target_groups = {
    alb = {
      name                  = local.service_name
      container_name        = local.service_name
      container_port        = 7800
      protocol              = "HTTP"
      health_check_protocol = "HTTP"
    }
  }
  elb_target_group_deregistration_delay = 60
  elb_target_group_vpc_id               = dependency.vpc.outputs.vpc_id
  health_check_path                     = "/index.json"
  default_listener_arns                 = dependency.alb.outputs.listener_arns
  default_listener_ports                = ["443"]

  # Configure the ALB listener rules to forward HTTPS traffic to the ECS service.
  forward_rules = {
    "default" = {
      listener_arns = [dependency.alb.outputs.listener_arns["443"]]
      port          = 443
      host_headers  = ["tiles.*"]
      path_patterns = ["*.pbf", "index.json"]
      http_headers = [{
        http_header_name = "x-alb-secret"
        values           = [dependency.shared_secret.outputs.secret]
      }]
      priority = 1
    }
  }

  # Configure the ALB listener rules to redirect HTTP traffic to HTTPS
  # This is handled in the ecs-eop-manager config, which uses the same ALB

  # -------------------------------------------------------------------------------------------------------------
  # CloudWatch Alarms
  # -------------------------------------------------------------------------------------------------------------

  alarm_sns_topic_arns = [dependency.sns.outputs.topic_arn]

  # -------------------------------------------------------------------------------------------------------------
  # Private common inputs
  # The following are common data (like locals) that can be used to construct the final input. We take advantage
  # of the fact that Terraform ignores extraneous variables defined in Terragrunt to make this work. We use _ to
  # denote these variables to avoid the chance of accidentally setting a real variable. We define these here
  # instead of using locals because locals can not reference dependencies.
  # -------------------------------------------------------------------------------------------------------------

  # Refer to the AWS docs for supported options in the container definition:
  # https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html
  container_definitions = [
    {
      name      = "${local.service_name}"
      image     = "${local.container_image}:${local.container_image_tag}"
      essential = true
      environment = [
        {
          name : "TS_CACHETTL",
          value : "3600"
        }
      ]
      secrets = [
        {
          name : "DATABASE_URL",
          valueFrom : "${dependency.eop_secrets.outputs.tileserver_config_arn}:DATABASE_URL::"
        }
      ]
      # The container ports that should be exposed from this container.
      portMappings = [
        {
          "containerPort" = 7800
          "protocol"      = "tcp"
        }
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
    dependency.eop_secrets.outputs.tileserver_config_arn,
  ]
}
