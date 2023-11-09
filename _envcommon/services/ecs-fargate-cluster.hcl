terraform {
  source = "${local.source_base_url}?ref=v0.107.5"
}

locals {
  source_base_url = "git::git@github.com:Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog.git//modules/services/ecs-fargate-cluster"

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account_vars.locals.account_name
}

inputs = {
  enable_container_insights = true
  cluster_name              = "services-${local.account_name}"
}
