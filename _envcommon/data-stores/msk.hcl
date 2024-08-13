terraform {
  source = "${local.source_base_url}?ref=v0.12.4"
}

dependency "eop_secrets" {
  config_path = "${get_terragrunt_dir()}/../../secrets"
  mock_outputs = {
    kafka_client_credentials_arn = "secret_arn"
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


locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-messaging.git//modules/msk"
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name    = local.account_vars.locals.account_name
}

inputs = {
  cluster_name                           = "kafka-${lower(local.account_name)}"
  cluster_size                           = 3
  kafka_version                          = "3.4.0"
  instance_type                          = "kafka.t3.small"
  vpc_id                                 = dependency.vpc.outputs.vpc_id
  subnet_ids                             = dependency.vpc.outputs.private_persistence_subnet_ids
  allow_connections_from_cidr_blocks     = dependency.vpc.outputs.private_app_subnet_cidr_blocks
  allow_connections_from_security_groups = [dependency.network_bastion.outputs.bastion_host_security_group_id]
  enable_client_sasl_scram               = true
  server_properties = {
    "auto.create.topics.enable"  = "true"
    "default.replication.factor" = "2"
    "log.retention.hours"        = "168"
  }
  client_sasl_scram_secret_arns = [
    dependency.eop_secrets.outputs.kafka_client_credentials_arn
  ]
}
