# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${local.source_base_url}?ref=v0.96.4"
}

dependency "acm_tls_certificate" {
  config_path                             = "${get_terragrunt_dir()}/../../../../us-east-1/acm-tls-certificates"
  mock_outputs_allowed_terraform_commands = ["validate", ]
  skip_outputs                            = true
}

generate "providers" {
  path      = "provider_extra.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  provider "aws" {
    # CloudFront resources require us-east-1 region, so we specify that here.
    region = "us-east-1"
    alias  = "us_east_1"
  }
EOF
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/services/public-static-website"
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  restrict_bucket_access_to_cloudfront    = true
  create_route53_entry                    = false
  base_domain_name                        = local.account_vars.locals.domain_name.name
  website_domain_name                     = "plan-limits.${local.account_vars.locals.domain_name.name}"
  acm_certificate_domain_name             = "${local.account_vars.locals.domain_name.name}"
  security_header_content_security_policy = "default-src 'self'; base-uri 'self'; block-all-mixed-content; font-src 'self' https: data:; form-action 'self'; frame-ancestors 'self'; img-src 'self' data:; object-src 'none'; script-src 'self' blob: https://api.mapbox.com/; script-src-attr 'none'; style-src 'self' https: 'unsafe-inline'; connect-src 'self' https://api.mapbox.com/ https://basemaps.linz.govt.nz/; upgrade-insecure-requests"
}