#!/bin/bash
#
# Script used by github to trigger infrastructure deployments via the infrastructure-deployer CLI utility on
# live infrastructure config.
#
# Required positional arguments, in order:
# - SOURCE_REF : The starting point for identifying all the changes. The diff between SOURCE_REF and REF will be
#                evaluated to determine all the changed files.
# - REF : The end point for identifying all the changes. The diff between SOURCE_REF and REF will be evaluated to
#         determine all the changed files.
# - COMMAND : The command to run. Should be one of plan or apply.
#
# Assumptions by script:
# - The script is run from a git repo corresponding to live infrastructure configurations (e.g., terragrunt modules).
# - There exists a json file named accounts.json at the root of the repo that maps AWS account names to AWS account IDs.
# - The first folder in the repository corresponds to AWS account names, and the accounts.json file contains an entry
#   for each folder.
#

set -e
set -o pipefail

# Locate the directory in which this script is located, and use that to determine where the helper functions are.
readonly script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path/helpers.sh"
# repo_url is the URL that ECS deploy runner will clone when running a job
readonly repo_url='https://github.com/Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure.git'

# Function that routes updates to various folders to specific CI/CD actions to take. For example, we ignore changes to
# to the ecs-deploy-runner folder as they contain infrastructure to manage the ECS deploy runner,
# and currently the deploy runner can't manage itself.
function route {
  local -r updated_folder="$1"

  # Add to this condition if you have other modules you do not want to manage with ECS deploy runner.
  if [[ "$updated_folder" == "." ]]; then
    echo "WARNING: A configuration in the repository root has changed. Because this could potentially impact many configurations, an operator must run a plan-all or apply-all manually in each account."
  # As of bash 3.2, do not use double quotes around regular expressions.
  elif [[ "$updated_folder" =~ ^.+/ecs-deploy-runner(/.+)?$ ]]; then
    echo "No action defined for changes to $updated_folder."
  elif [[ "$updated_folder" =~ ^_envcommon/mgmt/ecs-deploy-runner.hcl$ ]]; then
    echo "No action defined for changes to $updated_folder."
  else
    invoke_infrastructure_deployer "$@"
  fi
}

# Function that invokes the ECS Deploy Runner using the infrastructure-deployer CLI. This will also make sure to assume
# the correct IAM role based on the deploy path.
# ASSUMPTION: The infrastructure-live repository (this repo) is organized in a way such that the first folder is the AWS
# Account name (as it relates to the accounts.json file).
function invoke_infrastructure_deployer {
  local -r updated_folder="$1"
  local -r ref="$2"
  local -r command="$3"
  local -r command_args="$4"
  local -r source_ref="$5"
 
  local -r ecs_deploy_runner_region='ap-southeast-2'

  local assume_role_exports
  if [[ $updated_folder =~ ^.github(/.+)?$ ]] || [[ "$updated_folder" == "_ci" ]]; then
    # Don't return an error when .github folder is updated.
    echo "INFO: Skipping deployment of $updated_folder."
    exit 0
  elif [[ "$updated_folder" =~ ^([^/]+)/.*$ ]]; then
    # Process the folder path, where the first group is the environment.
    assume_role_exports="$(assume_role_for_environment "${BASH_REMATCH[1]}")"
  else
    echo "ERROR: Could not extract environment from deployment path $updated_folder."
    exit 1
  fi

  local -a args=(--aws-region "$ecs_deploy_runner_region" --)
  # Determine which container to run.
  if [[ "$command" == "plan" ]] || [[ "$command" == "plan-all" ]] || [[ "$command" == "validate" ]] || [[ "$command" == "validate-all" ]]; then
    args+=(terraform-planner infrastructure-deploy-script)
  else
    args+=(terraform-applier infrastructure-deploy-script)
  fi

  args+=(--ref "$ref" --binary "terragrunt" --command "$command" --command-args "$command_args" --deploy-path "$updated_folder" --repo "$repo_url" --force-https true)

  # Add --apply-ref-for-destroy arg if running plan/apply -destroy or destroy.
  if [[ "$command_args" =~ "-destroy" ]] || [[ "$command" == "destroy" ]]; then
    args+=(--apply-ref-for-destroy "$source_ref")
  fi

  echo "Running infrastructure-deployer with args: ${args[@]}"

  (eval "$assume_role_exports" && infrastructure-deployer "${args[@]}")
}

# Function that collects all the updated modules and calls the given command on the module using the infrastructure
# deployer.
function handle_updated_folders {
  local -r source_ref="$1"
  local -r ref="$2"
  local -r command="$3"

  # Use git-updated-folders to find all the terragrunt modules that changed, and pipe that via xargs to the
  # infrastructure-deployer.
  # Note that we ignore the _envcommon folder as that is handled in a different pipeline.
  local updated_folders
  updated_folders="$(
    git-updated-folders --source-ref "$source_ref" --target-ref "$ref" --terragrunt --ext yaml --ext yml --ext module_config.hcl --exclude-deleted \
      | (grep -Ev '^_envcommon' || true) | (grep -Ev '^modules' || true)
  )"

  # Run plan or apply on modified modules.
  if [[ -z "$updated_folders" ]]; then
    echo "No modules were updated. Skipping $command."
  else
    echo "The following modules were updated:"
    echo "$updated_folders"
    echo "Running $command on each updated module."
    echo "$updated_folders" \
      | xargs -r -I{} -n1 bash -c "set -o pipefail -e; echo \"Deploying {}\"; route {} \"$ref\" \"$command\""
  fi
}

# Function that collects all the updated envcommon files, and calls the given command on all the modules that include
# the common file.
function handle_updated_envcommon {
  local -r source_ref="$1"
  local -r ref="$2"

  # We convert the command to the *-all version so that we can delegate the responsibility of figuring out which modules
  # to run with terragrunt.
  local command="$3"
  if [[ "$command" == "plan" ]]; then
    command="plan-all"
  elif [[ "$command" == "apply" ]]; then
    command="apply-all"
  elif [[ "$command" == "validate" ]]; then
    command="validate-all"
  elif [[ "$command" == "destroy" ]]; then
    command="destroy-all"
  else
    echo "$command is not supported for handling updates to common files."
    exit 1
  fi

  # Use git-updated-files to find all the envcommon files that changed, and pipe that via xargs to the
  # infrastructure-deployer. Note that we pass in --exclude-ext so that we only capture changes to the common hcl files,
  # and not the individual module files.
  local updated_common_files
  updated_common_files="$(git-updated-files --source-ref "$source_ref" --target-ref "$ref" --ext .hcl --exclude-ext terragrunt.hcl --exclude-ext module_config.hcl)"

  # We also look for updated data files in the _envcommon directory, and pull in the related .hcl files.
  # We do this by running through git-updated-files looking for data file extensions (yaml + json), and then filtering
  # out anything that isn't in the _envcommon dir.
  # Note that in order to pull in related data files, we have to get the directory where the data file is defined so we
  # also feed the results through dirname and uniquify it.
  local xargs_options="-r"
  if [[ $(uname -s) == "Darwin" ]]; then
    xargs_options=""
  fi
  local updated_common_data_file_dirs
  updated_common_data_file_dirs="$(
    git-updated-files --source-ref "$source_ref" --target-ref "$ref" --ext .yaml --ext .yml --ext .json \
      | (grep -E '^_envcommon' || true) \
      | xargs ${xargs_options} -L1 dirname \
      | sort -u
  )"

  # For each common data file dir, make sure to extract all the common hcl files in that dir and add to the
  # updated_common_files list.
  if [[ -n "$updated_common_data_file_dirs" ]]; then
    # Note that this is the bash way to iterate a string variable line by line.
    # See https://superuser.com/questions/284187/bash-iterating-over-lines-in-a-variable
    local hcl_files_in_data_file_dir
    while IFS= read -r line; do
      hcl_files_in_data_file_dir="$(find "$line" -name "*.hcl")"
      # Prepend with newline. Note that because we are using double quote, we can't use the escape character for the
      # newline.
      updated_common_files+="
$hcl_files_in_data_file_dir"
    done <<< "$updated_common_data_file_dirs"
    # Trim leading and trailing whitespace by feeding to xargs
    # See https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable for an explanation.
    updated_common_files="$(echo "$updated_common_files" | xargs -L1)"
  fi

  # Run plan or apply on modified modules.
  if [[ -z "$updated_common_files" ]]; then
    echo "No modules were updated. Skipping $command."
  else
    echo "The following common files were updated:"
    echo "$updated_common_files"
    echo "Running $command on the children of each common file."

    # See above about how we iterate string variables line by line.
    local command_args
    while IFS= read -r line; do
      command_args+=" --terragrunt-modules-that-include=../$line"
    done <<< "$updated_common_files"
    command_args="$(echo "$command_args" | xargs)"

    # Run in each account, as opposed to each file, as the command_args captures all the files that need to run already.
    # The jq call does the following:
    # - Convert the json object to a list of objects {"key": KEY, "value": VALUE}
    # - Sort the list of objects by .value.deploy_order
    # - Extract the key attribute of the sorted list
    # Note that we append '|| exit 255' to the route command to ensure that xargs will halt the rollout if any
    # environment fails (xargs only halts on error with exit code 255).
    jq -r '[to_entries[]] | sort_by(.value.deploy_order)[] | .key' "$(get_git_root)/accounts.json" \
      | xargs -r -I{} -n1 bash -c "set -o pipefail -e; echo \"Deploying modules in {} that use common files\"; route \"{}/\" \"$ref\" \"$command\" \"$command_args\" || exit 255"
  fi
}

# Function that collects all the deleted modules and calls destroy on that module.
function handle_deleted_folders {
  local -r source_ref="$1"
  local -r ref="$2"
  local -r command="$3"

  # Use git-updated-folders to find all the terragrunt modules that were deleted, and pipe that via xargs to the
  # infrastructure-deployer.
  # Note that we ignore the _envcommon folder as that is handled in a different pipeline.
  local deleted_folders
  deleted_folders="$(
    git-updated-folders --source-ref "$source_ref" --target-ref "$ref" --terragrunt --ext yaml --ext yml --include-deleted-only \
      | (grep -Ev '^_envcommon' || true)
  )"

  if [[ -z "$deleted_folders" ]]; then
    echo "No modules were deleted. Skipping $command."
  else
    echo "The following modules were deleted:"
    echo "$deleted_folders"
    echo "Running $command -destroy on each deleted module."
    echo "$deleted_folders" \
      | xargs -r -I{} -n1 bash -c "set -o pipefail -e; echo \"Destroying {}\"; route {} \"$ref\" \"$command\" \"-destroy\" \"$source_ref\""
  fi
}

function run {
  local -r source_ref="$1"
  local -r ref="$2"
  local -r command="$3"

  # We must export the functions and vars so that they can be invoked through xargs
  export -f route
  export -f invoke_infrastructure_deployer
  export -f assume_role_for_environment
  export -f get_git_root
  export repo_url

  handle_deleted_folders "$source_ref" "$ref" "$command"
  handle_updated_envcommon "$source_ref" "$ref" "$command"
  handle_updated_folders "$source_ref" "$ref" "$command"
}

run "$@"
