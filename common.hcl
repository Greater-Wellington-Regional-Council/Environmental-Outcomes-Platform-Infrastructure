# Common variables for all AWS accounts.
locals {
  # ----------------------------------------------------------------------------------------------------------------
  # ACCOUNT IDS AND CONVENIENCE LOCALS
  # ----------------------------------------------------------------------------------------------------------------

  # Centrally define all the AWS account IDs. We use JSON so that it can be readily parsed outside of Terraform.
  accounts = jsondecode(file("accounts.json"))
  account_ids = {
    for key, account_info in local.accounts : key => account_info.id
  }

  # Define a default region to use when operating on resources that are not contained within a specific region.
  default_region = "ap-southeast-2"

  # A prefix used for naming resources.
  name_prefix = "gwrc"

  # All accounts use the ECR repo in the shared account for the ecs-deploy-runner docker image.
  deploy_runner_ecr_uri             = "${local.account_ids.shared}.dkr.ecr.${local.default_region}.amazonaws.com/ecs-deploy-runner"
  deploy_runner_container_image_tag = "v0.50.11"

  # All accounts use the ECR repo in the shared account for the Kaniko docker image.
  kaniko_ecr_uri             = "${local.account_ids.shared}.dkr.ecr.${local.default_region}.amazonaws.com/kaniko"
  kaniko_container_image_tag = "v0.50.4"

  # The infrastructure-live repository on which the deploy runner operates.
  infra_live_repo_https = "https://github.com/Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure.git"
  infra_live_repo_ssh   = "git@github.com:Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure.git"

  # These repos will be allowed for plan and apply operations in the CI/CD pipeline in addition to the value
  # provided in infra_live_repo_https
  additional_plan_and_apply_repos = [
    "https://github.com/gruntwork-clients/infrastructure-live-greater-wellington-regional-council.git",
  ]

  # The name of the S3 bucket in the Logs account where AWS Config will report its findings.
  config_s3_bucket_name = "${local.name_prefix}-config-logs"

  # The name of the S3 bucket in the Logs account where AWS CloudTrail will report its findings.
  cloudtrail_s3_bucket_name = "${local.name_prefix}-cloudtrail-logs"

  # The name of the S3 bucket where Macie will store sensitive data discovery results.
  macie_bucket_name_prefix = "${local.name_prefix}-macie-results"

  # The name of the KMS key that the above bucket will be encrypted with.
  macie_kms_key_name = "${local.name_prefix}-macie"

  # IAM configurations for cross account ssh-grunt setup.
  ssh_grunt_users_group      = "ssh-grunt-users"
  ssh_grunt_sudo_users_group = "ssh-grunt-sudo-users"
  allow_ssh_grunt_role       = "arn:aws:iam::${local.account_ids.security}:role/allow-ssh-grunt-access-from-other-accounts"

  # -------------------------------------------------------------------------------------------------------------------
  # COMMON NETWORK CONFIGURATION DATA
  # -------------------------------------------------------------------------------------------------------------------

  # Map of account name to VPC CIDR blocks to use for the mgmt VPC.
  mgmt_vpc_cidrs = {
    eopdev   = "172.31.80.0/20"
    eopprod  = "172.31.80.0/20"
    eopstage = "172.31.80.0/20"
    logs     = "172.31.80.0/20"
    security = "172.31.80.0/20"
    shared   = "172.31.80.0/20"
  }

  # Map of account name to VPC CIDR blocks to use for the app VPC.
  app_vpc_cidrs = {
    eopdev   = "10.0.0.0/16"
    eopprod  = "10.4.0.0/16"
    eopstage = "10.2.0.0/16"
  }

  # List of known static CIDR blocks for the organization. Administrative access (e.g., VPN, SSH,
  # etc) will be limited to these source CIDRs.
  vpn_ip_allow_list = [
    "0.0.0.0/0",
  ]
  ssh_ip_allow_list = [
    "0.0.0.0/0",
  ]

  # Information used to generate the CA certificate used by OpenVPN in each account
  ca_cert_fields = {
    ca_country  = "NZ"
    ca_email    = "eop_tech@gw.govt.nz"
    ca_locality = "Wellington"
    ca_org      = "GWRC"
    ca_org_unit = "ICT"
    ca_state    = "WG"
  }

  # Centrally define the internal services domain name configured by the route53-private module
  internal_services_domain_name = "gwrc.aws"
}
