# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for data-stores/redis. The common variables for each environment to
# deploy data-stores/redis are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.107.5-gwrc"
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies are modules that need to be deployed before this one.
# ---------------------------------------------------------------------------------------------------------------------

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
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/data-stores/redis"

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
  # Redis cluster name must be < 40 characters
  name = substr("redis-${local.name_prefix}-${lower(local.account_name)}", 0, 40)

  instance_type = "cache.t3.micro"
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_ids    = dependency.vpc.outputs.private_persistence_subnet_ids
  redis_version = "6.x"

  replication_group_size    = 1
  enable_multi_az           = false
  enable_automatic_failover = false
  parameter_group_name      = "default.redis6.x"
  enable_cloudwatch_alarms  = true
  alarms_sns_topic_arns     = [dependency.sns.outputs.topic_arn]

  # Here we allow any connection from the private app subnet tier of the VPC. You can further restrict network access by
  # security groups for better defense in depth.
  allow_connections_from_cidr_blocks     = dependency.vpc.outputs.private_app_subnet_cidr_blocks
  allow_connections_from_security_groups = [dependency.network_bastion.outputs.bastion_host_security_group_id]

  # Only apply changes during the scheduled maintenance window, as certain DB changes cause degraded performance or
  # downtime. For more info, see: https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/Clusters.Modify.html
  # We default to false, but in non-prod environments we set it to true to immediately roll out the changes.
  apply_immediately = false
}
