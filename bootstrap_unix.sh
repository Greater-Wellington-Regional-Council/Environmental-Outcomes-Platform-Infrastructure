#!/usr/bin/env bash

GRUNTWORK_INSTALLER_VERSION=v0.0.38
GRUNTWORK_INSTALLER_URL="https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh"
GRUNTWORK_CLI_BINARY_NAME="gruntwork"
GRUNTWORK_CLI_REPO="https://github.com/gruntwork-io/gruntwork"

WRONG_DIR_ERROR="You must run your bootstrap script from within your local working copy of your specific gruntwork-clients infrastructure-live repository. This repository will likely be named gruntwork-clients/infrastructure-live-<your-company> in GitHub."

# User must have git installed, so bail out if they need to install it
ensure_git_installed() {
  ensure_binary_installed "git"
}

# This script needs to be run in the local checkout of the user's infrastructure-live repo
# since we are using git to determine the repo name that we can use to verify the user's
# access to their own specifically-assigned gruntwork-clients repo
ensure_run_in_infra_live_repo() {
  # Sanity check that the script is being run in a git repo
  git status || { echo $WRONG_DIR_ERROR;  exit 1; }

  repo_name=$(get_repo_name)

  # If the present working directory does not end with the name of the
  # remote git repo, then it's unlikely the script is being run in the correct dir
  if [[ $PWD != *$repo_name ]]; then
    echo "$WRONG_DIR_ERROR"; exit 1;
  fi
}

# greeting prints out a simple intro to the user to set the context for what we're doing and why
greeting() {
  echo " "
  echo "****************************************************"
  echo "* Welcome to the Gruntwork Ref Arch setup process! *"
  echo "****************************************************"
  echo " "
  echo "This script will install everything you need to prepare for your deployment"
  echo " "
  echo "Once the setup tooling is installed, this script will commence a Gruntwork wizard that automates a lot of the setup for you"
  echo " "
}

get_repo_name() {
  basename `git rev-parse --show-toplevel` || { echo "Error: could not determine git repo name"; exit 1; }
}

# ensure_github_pat_exported does a sanity check that the user has a valid GITHUB_OAUTH_TOKEN exported
ensure_github_pat_exported() {
  if [ -z "${GITHUB_OAUTH_TOKEN}" ]; then
    echo "You must have a valid GitHub Personal Access Token (PAT) exported as GITHUB_OAUTH_TOKEN"
    exit 1
  fi
  repo_name=$(get_repo_name)
  # Perform sanity checks to ensure user can access both gruntwork-io and gruntwork-clients
  ensure_github_org_access "gruntwork-io" "gruntwork"
  ensure_github_org_access "gruntwork-clients" "$repo_name"
}

ensure_github_org_access() {
  local -r org_name="$1"
  local -r repo_name="$2"

  echo "Running access sanity check to ensure you have access to GitHub organization $org_name and repo $repo_name"
  # Make a CURL call to the GitHub API's repos endpoint, supplying the user's GITHUB_OAUTH_TOKEN to ensure
  # they have sufficient access to the provided org. This check is used to ensure access to both
  # gruntwork-io and gruntwork-clients, as ref arch customers must have access to both prior to deployment
  status_code=$(
    curl \
    -H "Authorization: Bearer ${GITHUB_OAUTH_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    --write-out '%{http_code}' -IsS --output /dev/null "https://api.github.com/repos/$org_name/$repo_name"
  )
  if [[ "$status_code" -eq 404 ]]; then
    echo "ACCESS ERROR: It looks like you don't have access to the $org_name GitHub organization or to repo $repo_name"
    echo "Please confirm you've already been invited to $org_name and accepted your invite"
    echo "If you need help, please email support@gruntwork-io and explain you need an invite to the Gruntwork GitHub orgs"
    echo ""
    exit 1
  fi

  if [[ "$status_code" -eq 200 ]]; then
    echo "Success: Confirmed you have access to the $1 GitHub organization and repo $2"
  fi
  echo " "
}

# install_gruntwork_staller fetches the version of gruntwork-installer configured in $GRUNTWORK_INSTALLER_VERSION
# from the URL specified in $GRUNTWORK_INSTALLER_URL
install_gruntwork_installer() {
  echo "Installing gruntwork-install, a utility that knows how to install additional Gruntwork tooling on your system..."
  curl \
    -LsS \
    "$GRUNTWORK_INSTALLER_URL" | bash /dev/stdin --version "$GRUNTWORK_INSTALLER_VERSION"
  # Ensure the gruntwork-installer is installed properly and can be found
  ensure_binary_installed "gruntwork-install"
}

# install_gruntwork_cli fetches and installs the Gruntwork CLI golang binary, which contains our streamlined
# Ref Arch setup experience
install_gruntwork_cli() {
  echo "Installing the gruntwork command line interface (CLI), which contains a helpful wizard to walk you through your Ref Arch setup steps"
  gruntwork-install \
    --binary-name "$GRUNTWORK_CLI_BINARY_NAME" \
    --repo "$GRUNTWORK_CLI_REPO" \
    --tag "~> 0.3.0" # get latest 0.3.x version
  # Ensure the gruntwork binary is installed properly and can be found
  ensure_binary_installed "gruntwork"
}

# ensure_binary_installed will exit with an error if the supplied binary is missing
ensure_binary_installed() {
  local -r binary="$1"
  if ! os_command_is_installed "$binary"; then
    echo "Missing required binary $binary"
    echo "Please reach out to support@gruntwork.io"
    exit 1
  fi
}

# Lifted from gruntwork-io/bash-commons
os_command_is_installed(){
  local -r name="$1"
  command -v "$name" > /dev/null
}

# commence_gruntwork_wizard presents the user with a simple prompt asking them
# if they'd like to commence their setup wizard. If they enter Y or y, the wizard is invoked
# If the enter N or n or press ctrl+c, execution terminates
commence_gruntwork_wizard() {
  local -r repo_name="$1"

  echo "All of the setup dependencies have been successfully installed!"
  PROMPT="Would you like to commence the setup wizard now?

          Please enter Y or y for Yes

          Or enter N or n or press ctrl+c to quit

          Proceed with wizard?: "
  while true; do
    read -p "$PROMPT" yn
    case $yn in
        [Yy]* ) GRUNTWORK_CLIENTS_INFRA_LIVE_REPO_NAME="$repo_name" gruntwork wizard; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y or n.";;
    esac
done
}

ensure_git_installed
ensure_run_in_infra_live_repo
greeting
ensure_github_pat_exported
install_gruntwork_installer
install_gruntwork_cli
commence_gruntwork_wizard
