# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mgmt/bastion-host. The common variables for each environment to
# deploy mgmt/bastion-host are defined here. This configuration will be merged into the environment configuration
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

# While the bastion is a "Management" component, it needs to be deployed into the "App" VPC to have access to app services
# that is without VPC peering.
dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../${local.account_name}/networking/vpc"

  mock_outputs = {
    vpc_id            = "vpc-abcd1234"
    vpc_cidr_block    = "10.0.0.0/16"
    public_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "sns" {
  config_path = "${get_terragrunt_dir()}/../../_regional/sns-topic"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-1:123456789012:mytopic-NZJ5JSMVGFIE"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/mgmt/bastion-host"

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

  shared_account_id = local.common_vars.locals.account_ids.shared
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name          = "bastion"
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_id     = dependency.vpc.outputs.public_subnet_ids[0]
  instance_type = "t3.micro"
  ami           = ""
  ami_filters = {
    owners = [local.shared_account_id]
    filters = [
      {
        name   = "name"
        values = ["bastion-host-v0.96.9-*"]
      },
    ]
  }

  # Access to the Bastion Host via SSH should be limited to specific, known CIDR blocks.
  allow_ssh_from_cidr_list = local.common_vars.locals.ssh_ip_allow_list

  # Access the VPN server over SSH using ssh-grunt.
  # See: https://github.com/Greater-Wellington-Regional-Council/gwio_terraform-aws-security/blob/master/modules/ssh-grunt
  enable_ssh_grunt                    = true
  ssh_grunt_iam_group                 = local.common_vars.locals.ssh_grunt_users_group
  ssh_grunt_iam_group_sudo            = local.common_vars.locals.ssh_grunt_sudo_users_group
  external_account_ssh_grunt_role_arn = local.common_vars.locals.allow_ssh_grunt_role

  alarms_sns_topic_arn = [dependency.sns.outputs.topic_arn]

  keypair_name = "bastion-admin-v1"

  # The primary domain name for the environment - the bastion server will prepend "bastion." to this
  # domain name and create a route 53 A record in the correct hosted zone so that the bastion server is
  # publicly addressable
  domain_name = local.account_vars.locals.domain_name.name
}
