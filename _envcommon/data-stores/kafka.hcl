terraform {
  source = "../../../../..//modules//msk-serverless"
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
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account_vars.locals.account_name  
}

inputs = {
  cluster_name    = "kafka-${lower(local.account_name)}"
  cluster_size    = 3
  kafka_version   = "3.3.1"
  instance_type   = "kafka.t3.small"
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_persistence_subnet_ids
  allowed_inbound_cidr_blocks = dependency.vpc.outputs.private_app_subnet_cidr_blocks
  allowed_inbound_security_group_ids = [dependency.network_bastion.outputs.bastion_host_security_group_id]
  enable_client_sasl_scram = true
}
