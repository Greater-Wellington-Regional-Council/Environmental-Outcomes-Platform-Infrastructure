#!/bin/bash
#
# Helper functions for use with CI server scripts to manage infrastructure deployments.

# Locate root of git repo
function get_git_root {
  git rev-parse --show-toplevel
}

# A function that uses aws-auth to assume the IAM role for invoking the ECS Deploy Runner.
function assume_role_for_environment {
  local -r environment="$1"

  # We lookup the account ID from the accounts.json file.
  local account_id
  account_id="$(jq -r ".\"$environment\".id" "$(get_git_root)/accounts.json")"
  if [[ "$account_id" == "null" ]]; then
    echo "ERROR: Unknown environment $environment. Can not assume role."
    exit 1
  fi

  aws-auth --role-arn "arn:aws:iam::$account_id:role/allow-auto-deploy-from-other-accounts" --role-duration-seconds 3600
}
