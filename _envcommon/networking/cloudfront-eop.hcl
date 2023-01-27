terraform {
  source = "../../../../..//modules//cloudfront-eop"
}

dependency "alb" {
  config_path = "${get_terragrunt_dir()}/../../networking/alb-eop-manager"
}

dependency "tileserver" {
  config_path = "${get_terragrunt_dir()}/../../services/ecs-eop-tileserver"
}

dependency "eop_shared_secret" {
  config_path = "${get_terragrunt_dir()}/../../services/eop-shared-secret"
  mock_outputs = {
    secret = "secret"
  }
}

dependency "route53" {
  config_path = "${get_terragrunt_dir()}/../../../../_global/route53-public"
}

dependency "acm_tls_certificate" {
  config_path = "${get_terragrunt_dir()}/../../../../us-east-1/acm-tls-certificates"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  alb_dns_name = dependency.alb.outputs.original_alb_dns_name  
  hosted_zone_id = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]
  domain_name = "tiles.${local.account_vars.locals.domain_name.name}"
  # TODO: Check this is OK hardcoded to 0
  acm_certificate_arn = dependency.acm_tls_certificate.outputs.certificate_arns[0]
  alb_http_header_secret = dependency.eop_shared_secret.outputs.secret
}
