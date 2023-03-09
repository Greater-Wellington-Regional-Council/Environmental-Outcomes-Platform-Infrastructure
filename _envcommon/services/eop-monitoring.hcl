terraform {
  source = "../../../../..//modules//eop-monitoring"
}

dependency "sns" {
  config_path = "${get_terragrunt_dir()}/../../../_regional/sns-topic"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-1:123456789012:mytopic-NZJ5JSMVGFIE"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "alb-eop-manager" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb-eop-manager"

  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:ap-southeast-2:123456:loadbalancer/app/name/123456789"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "ecs-eop-manager" {
  config_path = "${get_terragrunt_dir()}/../ecs-eop-manager"

  mock_outputs = {
    service_arn = "arn:aws:ecs:ap-southeast-2:123456789:service/name/name"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account_vars.locals.account_name
  service_name = "eop-manager"
}

inputs = {
  eop_manager_log_group_name = "/${local.account_name}/ecs/${local.service_name}"
  alarms_sns_topic_arn       = [dependency.sns.outputs.topic_arn]
  eop_alb_arn                = dependency.alb-eop-manager.outputs.alb_arn
}
