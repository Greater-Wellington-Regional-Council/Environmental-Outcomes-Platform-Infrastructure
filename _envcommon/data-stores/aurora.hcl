# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for data-stores/aurora. The common variables for each environment to
# deploy data-stores/aurora are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.107.5-gwrc"
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
    vpc_id                         = "vpc-abcd1234"
    private_persistence_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
    private_app_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", ]
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

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/data-stores/aurora"

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name and account_role for easy access
  account_name = local.account_vars.locals.account_name
  account_role = local.account_vars.locals.account_role

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name              = "aurora-${lower(local.account_name)}"
  instance_type     = "db.t4g.large"
  vpc_id            = dependency.vpc.outputs.vpc_id
  aurora_subnet_ids = dependency.vpc.outputs.private_persistence_subnet_ids

  instance_count = "1"
  engine_mode    = "provisioned"
  engine_version = "15.4"

  enable_cloudwatch_alarms          = true
  alarms_sns_topic_arns             = [dependency.sns.outputs.topic_arn]
  performance_insights_enabled      = true
  too_many_db_connections_threshold = 100

  # Here we allow any connection from the private app subnet tier of the VPC. You can further restrict network access by
  # security groups for better defense in depth.
  allow_connections_from_cidr_blocks     = dependency.vpc.outputs.private_app_subnet_cidr_blocks
  allow_connections_from_security_groups = [dependency.network_bastion.outputs.bastion_host_security_group_id]
  iam_database_authentication_enabled    = true

  db_config_secrets_manager_id = dependency.eop_secrets.outputs.aurora_rds_config_arn


  # Only apply changes during the scheduled maintenance window, as certain DB changes cause degraded performance or
  # downtime. For more info, see: https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/Clusters.Modify.html
  # We default to false, but in non-prod environments we set it to true to immediately roll out the changes.
  apply_immediately = false

  db_cluster_custom_parameter_group = {
    name   = "custom-aurora-postgresql15"
    family = "aurora-postgresql15"
    parameters = [
      {
        name         = "log_temp_files"
        value        = "64"
        apply_method = "immediate"
      },
      {
        name         = "shared_preload_libraries"
        value        = "pg_stat_statements"
        apply_method = "immediate"
      }
    ]
  }
}
