terraform {
  source = "../../../../..//modules//cdn"
}

dependency "acm_tls_certificate" {
  config_path = "${get_terragrunt_dir()}/../../../../us-east-1/acm-tls-certificates"
}

dependency "route53" {
  config_path = "${get_terragrunt_dir()}/../../../../_global/route53-public"
}

dependency "alb" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb-eop-manager"
}

dependency "shared_secret" {
  config_path = "${get_terragrunt_dir()}/../ecs-eop-tileserver-secret"
  mock_outputs = {
    secret = "secret"
  }
}

dependency "tileserver" {
  config_path = "${get_terragrunt_dir()}/../ecs-eop-tileserver"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  domain_name = "tiles.${local.account_vars.locals.domain_name.name}"
  acm_certificate_arn = dependency.acm_tls_certificate.outputs.certificate_arns[0]
  hosted_zone_id = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]
  alb_dns_name = dependency.alb.outputs.original_alb_dns_name
  alb_http_header_secret = dependency.shared_secret.outputs.secret
}
