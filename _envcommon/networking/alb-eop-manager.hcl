terraform {
  source = "${local.source_base_url}?ref=v0.107.5"
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../networking/vpc"

  mock_outputs = {
    vpc_id            = "vpc-abcd1234"
    public_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "route53" {
  config_path = "${get_terragrunt_dir()}/../../../../_global/route53-public"

  mock_outputs = {
    public_hosted_zone_map = {
      ("${local.account_vars.locals.domain_name.name}") = "some-zone"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/networking/alb"

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

inputs = {
  # Since this is an external public facing ALB, we deploy it into the app VPC, inside the public tier.
  is_internal_alb = false
  vpc_id          = dependency.vpc.outputs.vpc_id
  vpc_subnet_ids  = dependency.vpc.outputs.public_subnet_ids

  # Since this is a public-facing ALB, we allow access from the entire Internet
  allow_inbound_from_cidr_blocks = ["0.0.0.0/0"]

  http_listener_ports = [80]
  https_listener_ports_and_acm_ssl_certs = [
    {
      port            = 443
      tls_domain_name = "${local.account_vars.locals.domain_name.name}"
    }
  ]

  create_route53_entry = true
  hosted_zone_id       = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]
  domain_names         = ["data.${local.account_vars.locals.domain_name.name}"]

  num_days_after_which_archive_log_data = 7
  num_days_after_which_delete_log_data  = 30
  force_destroy                         = true
}
