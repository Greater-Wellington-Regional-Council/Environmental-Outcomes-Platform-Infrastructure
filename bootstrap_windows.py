import os
import subprocess
import stat
import sys
import json
import logging
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import platform
import pathlib
from shutil import which


# Vars determining where we will attempt to install the Gruntwork CLI binary
target_path_root = os.path.expanduser("~/")
target_path_dir = "GruntworkWizard"
target_binary_name = "gruntwork.exe"
complete_install_path = os.path.join(target_path_root, target_path_dir, target_binary_name)

logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=logging.INFO)

missing_github_pat_error = 'You must export a valid GitHub Personal Access Token (PAT) as GITHUB_OAUTH_TOKEN'


# Error messages
wrong_dir_err = "Could not successfully run git command in your current directory. Please ensure you are running bootstrap_windows.py in your local infrastructure-live repository"

windows_releases = {
    "x86_64": "gruntwork_windows_amd64.exe",
    "AMD64": "gruntwork_windows_amd64.exe"
}
releases = {
    "windows": windows_releases
}

def ensure_running_on_windows():
    """
    Sanity checks that this script is being run on Windows

    Raises:
        Exception: bootstrap_windows.py must be run on a Windows system
    """
    if get_current_platform() != "windows":
        raise Exception("bootstrap_windows.py is only intended to be run on a Windows system! Please see bootstrap_unix.sh instead.")


def ensure_binary_installed(name):
    """
     Ensure a binary is installed by raising an exception if its not

     Raises:
         Exception: requested binary is not installed
    """
    if not is_binary_installed(name):
        raise Exception(f"You must install {name} first before you can run this script")


def is_binary_installed(name):
    """Check whether `name` is on PATH and marked as executable."""

    return which(name) is not None


def ensure_running_in_infra_live():
    """
    Sanity checks that this script is being run in the local infra-live repo

    Raises:
        Exception: bootstrap_windows.py must be run within your infrastructure-live repo
    """
    cwd = os.getcwd()
    normalized_cwd = pathlib.PureWindowsPath(cwd)
    script_running_dir = normalized_cwd.name

    repo_name = get_repo_name()

    if script_running_dir != repo_name:
        raise Exception(wrong_dir_err)


def get_repo_name():
    """
    Determine the user's repo name by asking git

    Raises:
        Exception: git command returned an error
    """
    process = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True)
    # if there was any error running the git command, that's an indication the script is likely not being
    # run from within the infrastructure-live repository
    if process.returncode != 0:
        raise Exception(wrong_dir_err)

    cmdReturn = process.stdout.strip().decode("utf-8")
    # Normalize the path and then split and retrieve the last path item to get just the repo name
    repo_path = cmdReturn
    normalized_path = pathlib.PureWindowsPath(repo_path)
    repo_name = normalized_path.name
    return repo_name


def get_github_url(token, url, overrideHeaders):
    """
    Uses the supplied token to fetch the supplied GitHub URL
    """
    headers = {'Authorization': f'token {token}',
               'Accept': 'application/vnd.github.v3+json'}

    # If any "override" headers were supplied, use them instead of the currently configured value
    for key, val in overrideHeaders.items():
        if key in headers:
            headers[key] = val

    req = Request(url, None, headers)
    try:
        response = urlopen(req)
    except HTTPError as e:
        logging.info(f"There was an error fetching the GitHub URL {url}:{e.reason}")
        raise e
    else:
        return response


def ensure_github_org_access(token, org, repo):
    """
    Ensure that the user's exported GITHUB_OAUTH_TOKEN can reach both gruntwork-io and gruntwork-clients orgs

    Raises:
        Exception: Could not access a GitHub organization
    """
    logging.info(f"Testing your access to the {org} GitHub organization and {repo} repo...")
    # Format the API call to the org and repo
    test_url = f"https://api.github.com/repos/{org}/{repo}"
    resp = get_github_url(token, test_url, {})

    if resp.getcode() == 200:
        print("Success! Confirmed you have the required access", file=sys.stdout)
    elif resp.getcode() == 404:
        print(f"Could not access repo {repo} under GitHub organization {org} with your token", file=sys.stderr)
        print(f"Please ensure you've accepted an invite to the {org} organization", file=sys.stderr)
        print("You can reach us at support@gruntwork.io if you need assistance", file=sys.stderr)
        raise Exception(f"Could not access {org} GitHub organization", file=sys.stderr)


def lookup_platform_binary_name(platform, machine):
    """
    Return the correct binary name for the supplied platform and machine, if it exists
    """
    if platform in releases:
        if machine in releases[platform]:
            return releases[platform][machine]


def get_current_platform():
    """
    Return the current system's platform name, in lower case (windows, linux, darwin, etc)
    """
    return platform.system().lower()



def install_gruntwork_cli(token):
    """
    Look up the Gruntwork command line interface (CLI) release assets via a known release tag
    """
    # Get GitHub release by tag name
    logging.info("Looking up gruntwork command line interface (CLI) releases")
    release_url = "https://api.github.com/repos/gruntwork-io/gruntwork/releases/latest"
    return get_github_url(token, release_url, {})


def ensure_path_exists(path):
    """
    If supplied path does not exist, create it
    """
    if not os.path.exists(path):
        pathlib.Path(path).mkdir(parents=True, exist_ok=True)


def download_binary(token, url):
    """
    Download the release asset at the supplied URL
    """
    # GitHub API docs specify that we must set this Accept header when
    # attempting to download a release asset:
    # https://docs.github.com/en/rest/releases/assets#get-a-release-asset
    headers = {'Accept': 'application/octet-stream'}
    # Override default GitHub headers and make the API call for the asset
    resp = get_github_url(token, url, headers)

    # If the response's status code is not 200, we've got a show-stopping problem
    if resp.getcode() != 200:
        raise Exception("Received error response from GitHub when attempting to download asset")
    else:
        logging.info("Succeeded in fetching asset from GitHub")

    user_downloads_path = 'Downloads'
    binary_name = 'gruntwork'

    # Form the path to the directory where we're going to put the downloaded binary
    save_to_dir = os.path.join(target_path_root, user_downloads_path)

    # Ensure the path exists, creating it if it doesn't
    ensure_path_exists(save_to_dir)

    save_to = os.path.join(target_path_root, user_downloads_path, binary_name)

    logging.info(f"Attempting to save Gruntwork Wizard binary to {save_to}")

    # Write the bytes to the file
    with open(save_to, "wb") as binary_file:
        binary_file.write(resp.read())
    return save_to


def remove_previous_binary_if_exists(path):
    """
    If the supplied path exists, attempt to remove it

    Used to clean up pre-existing binaries found at a target path during installation
    """
    if os.path.exists(path):
        os.remove(path)


def move_binary(download_path):
    """
    Move the binary from the download path to its destination path
    """

    user_home_path = os.path.expanduser(target_path_root)

    # Form the path to the directory where we'll store the gruntwork binary
    dest_dir = os.path.join(user_home_path, target_path_dir)

    # If the directory doesn't already exist, create it
    ensure_path_exists(dest_dir)

    # Form the full filepath path to the binary within the target directory
    dest_path = os.path.join(dest_dir, target_binary_name)

    logging.info(f"Attempting to move Gruntwork Wizard binary to {dest_path}")

    # Remove any pre-existing gruntwork binaries we may find there - in case
    # this script was run more than once
    remove_previous_binary_if_exists(dest_path)

    # Move the downloaded gruntwork binary to the target installation path and
    # return the path so we can further operate on it in subsequent calls
    os.rename(download_path, dest_path)
    return dest_path


def make_executable(binary_path):
    """
    Make the binary executable by the user
    """
    st = os.stat(binary_path)
    os.chmod(binary_path, st.st_mode | stat.S_IEXEC)
    return binary_path


def invoke_wizard(gruntwork_wizard_path, repo_name):
    """
    Attempts to invoke the gruntwork wizard which we just installed. Because we don't have ultimate confidence in being able to
    correctly update the Windows PATH system variable, we wrap this in a try / except block and output a helpful error if we fail
    """
    logging.info(f"Attempting to run the Gruntwork boostrapping wizard located at {gruntwork_wizard_path}")
    try:
        # The full command will be the complete path to the gruntwork.exe file, plus the word "wizard"
        # which is a sub-command of the gruntwork CLI
        # We use execle instead of system so that we can replace the current running process with the wizard.
        # Inherit the current process environment variable, but enhance it with additional parameters that we want to
        # pass to the wizard.
        proc_env = dict(os.environ)
        proc_env["GRUNTWORK_CLIENTS_INFRA_LIVE_REPO_NAME"] = repo_name
        os.execle(gruntwork_wizard_path, "wizard", proc_env)
    except Exception as e:
        logging.info(e)
        logging.info("Oops! Failed to run the gruntwork wizard for you, but you should still be able to find and run it yourself")
        logging.info(f"Your wizard should be installed at {complete_install_path}")
        logging.info("You may need to update your PATH to include this directory")


def main():
    """
    Perform GitHub Org access sanity checks, then install the gruntwork CLI and commence the wizard
    """
    # Raise an exception if this script is not run on a Windows system
    ensure_running_on_windows()

    # Raise an exception if user does not have git installed
    ensure_binary_installed("git")

    # Ensure the script is being run within local infrastructure-live repo
    ensure_running_in_infra_live()

    # Sanity check that user has GITHUB_OAUTH_TOKEN env var exported
    token = os.environ.get("GITHUB_OAUTH_TOKEN")
    if not token:
        raise Exception(missing_github_pat_error)
    # We need to ensure the user has access to both gruntwork-io and gruntwork-clients
    # as new Ref Arch customers require both

    # Sanity check that user's PAT can access gruntwork-io/gruntwork
    ensure_github_org_access(token, "gruntwork-io", "gruntwork")
    # Sanity check that user's PAT can access gruntwork-clients/infrastructure-live
    ensure_github_org_access(token, "gruntwork-clients", get_repo_name())

    # Install the gruntwork command line interface (CLI) which contains the streamlined
    # ref arch form setup experience
    resp = install_gruntwork_cli(token)

    # Look up the operator's  platform details so we can choose the correct release binary
    curr_plat = get_current_platform()
    machine = platform.machine()

    # Read the GitHub response and parse as JSON
    encoding = resp.info().get_content_charset('utf-8')
    github_json = json.loads(resp.read().decode(encoding))

    logging.info(f"Your current platform is {curr_plat} and your architecture is {machine}")

    binary_download_url = ""

    target_binary_name = lookup_platform_binary_name(curr_plat, machine)
    if not target_binary_name:
        raise Exception(f"Could not determine your platform and architecture's corresponding binary")

    binary_download_url = ""
    for asset in github_json['assets']:
        if asset['name'] == target_binary_name:
            logging.info(f"Found {curr_plat} {machine} release for Gruntwork CLI")
            binary_download_url = asset['url']

    if len(binary_download_url) == 0:
        raise Exception(f"Could not find compatible Gruntwork CLI release for your platform {curr_plat} and architecture {machine}")

    logging.info(f"binary_download_url is {binary_download_url}".format(url=binary_download_url))

    # Download the binary to the user's machine
    download_path = download_binary(token, binary_download_url)

    # Move binary to our target installation path
    dest_path =  move_binary(download_path)

    # Make binary executable
    dest_path = make_executable(dest_path)

    # Attempt to invoke the Gruntwork Wizard
    invoke_wizard(dest_path)


if __name__ == '__main__':
    main()
