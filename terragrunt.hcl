# ----------------------------------------------------------------------------------------------------------------
# This is the root configuration for infrastructure-live. Its purpose is to:
#
#   - generate a provider block to configure the Terraform provider for AWS
#   - generate a remote state block for storing state in S3
#   - define a minimal set of global inputs that may be needed by any file
#
# Each module within infrastructure-live includes this file.
# ----------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------
# LOAD COMMON VARIABLES
# ----------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract commonly used variables for easy acess
  name_prefix  = local.common_vars.locals.name_prefix
  account_name = local.account_vars.locals.account_name
  account_id   = local.common_vars.locals.account_ids[local.account_name]
  aws_region   = local.region_vars.locals.aws_region
}

# ----------------------------------------------------------------------------------------------------------------
# GENERATED PROVIDER BLOCK
# ----------------------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

# Use an override file to lock the provider version, regardless of if required_providers is defined in the modules.
generate "provider_version" {
  path      = "provider_version_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25"
    }
  }
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------
# GENERATED REMOTE STATE BLOCK
# ----------------------------------------------------------------------------------------------------------------
# Generate the Terraform remote state block for storing state in S3
remote_state {
  backend = "s3"
  config = {
    encrypt                   = true
    bucket                    = lower("${local.name_prefix}-${local.account_name}-${local.aws_region}-tf-state")
    key                       = "${path_relative_to_include()}/terraform.tfstate"
    region                    = local.aws_region
    dynamodb_table            = "terraform-locks"
    accesslogging_bucket_name = lower("${local.name_prefix}-${local.account_name}-${local.aws_region}-tf-logs")
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
# ----------------------------------------------------------------------------------------------------------------
# DEFAULT INPUTS
# ----------------------------------------------------------------------------------------------------------------
inputs = {
  # Set globally used inputs here to keep all the child terragrunt.hcl files more DRY.
  aws_account_id = local.account_id
  aws_region     = local.aws_region
  name_prefix    = local.common_vars.locals.name_prefix
}

#-----------------------------------------------------------------------------------------------------------------
# ALLOW .terraform-version FILE TO BE COPIED
#-----------------------------------------------------------------------------------------------------------------
terraform {
  include_in_copy = [".terraform-version"]
}
