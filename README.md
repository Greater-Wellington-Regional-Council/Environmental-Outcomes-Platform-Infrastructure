# Gruntwork Reference Architecture Setup Instructions

This repository is used to generate the code to deploy and manage the [the Gruntwork Reference Architecture](https://gruntwork.io/reference-architecture/). When we have finished the initial deployment, all of the code will be committed to this repository. You will receive an automated email at the end of the deployment indicating that the initial deployment has finished, which includes instructions for copying the code to your own repository outside of the `gruntwork-clients` GitHub organization.

![Landing Zone Reference Architecture](/assets/landing-zone-ref-arch.png)

## Step 1. Create an infrastructure-live repository

1. Create a new repository in your VCS platform. We recommend naming it _infrastructure-live_.
1. Keep this repo handy, as you'll be prompted for the following information in a subsequent step:
    - HTTPS URL (e.g. `https://github.com/gruntwork-io/infrastructure-live`)
    - SSH URL (e.g. `git@github.com:gruntwork-io/infrastructure-live.git`)
    - Default branch (e.g. `main` or `master`)


## Step 2. Set up the machine user

Whatever VCS platform you are using, do this:

1. In GitHub, log in as the machine user you would like to use for CI/CD (if you don't have one, create a new user account), then create a [Personal Access Token (PAT)](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) for that user.
1. The PAT should be granted `repo`, `user:email`, and `admin:public_key` permissions.
1. In the [Gruntwork developer portal](https://app.gruntwork.io/), add the user to your team, then log in to the portal _as the machine user_ and link the GitHub account. You’ll know it’s set up correctly when you see the Gruntwork icon in the machine user’s GitHub profile, indicating that they are a member of the Gruntwork Organization.
1. Once you have the PAT, store it somewhere secure and handy, as you'll be asked for it soon in a subsequent wizard step.

If you are using GitHub as your VCS, you’re done with this section! If you’re using GitLab or BitBucket, do the following:

- Log in as the machine user in the selected VCS platform (GitLab or BitBucket).

- For GitLab, use [these instructions](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html), and
  grant the following scopes (NOTE: `api` and `read_user` scopes are only used for uploading the public SSH
  key for the user. You can replace the token with a new one that only has `write_repository` permission after the
  Reference Architecture is deployed.):

  - `write_repository`
  - `api`
  - `read_user`

- For Bitbucket, use [these instructions](https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/), and
  grant the following scopes (NOTE: `Account:Write` is only used for uploading the public SSH key for the user. You can
  replace the token with a new one that only has `Repositories:Write` permission after the Reference Architecture is
  deployed.):

  - `Repositories:Write`
  - `Account:Write`


## Step 3. Clone this repository

Use Git to clone this repository. If you do not have `git` available on your system, refer to [these instructions](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) to install Git on your platform.

1. Clone the repository.

   ```bash
   git clone git@github.com:gruntwork-clients/<this-repo>.git
   ```


## Step 4. Authenticate to AWS on your command line

The bootstrap script will prepare your AWS accounts for deployment. To use the bootstrap script and form filling wizard,
the CLI will need access to your AWS Root account you would like to use for the Reference Architecture. The Root account
is where the AWS Organization is defined.

1. If you do not have a Root account (an AWS account with AWS Organizations setup) already, create one. We recommend
   creating a brand new account to use as the Root account if you are not already using AWS Organizations, and import
   your existing AWS Account(s) to it as members.
1. Setup AWS Organizations in your Root account if you haven't already. Refer to [this
   documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tutorials_basic.html) for instructions
   on how to setup AWS Organizations.
1. If you do not have one already, [create an IAM
   User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) with administrator permissions (attach
   the `AdministratorAccess` IAM policy). Make sure to create AWS Access Keys for the IAM User as well.
1. Once you have an IAM User and AWS Access Keys for accessing the Root account, configure your terminal to be able to
   authenticate to the IAM User. If you do not know how to do this, refer to our [Comprehensive Guide to Authenticating
   to AWS on the Command
   Line](https://blog.gruntwork.io/a-comprehensive-guide-to-authenticating-to-aws-on-the-command-line-63656a686799).


## Step 5. Run the bootstrap script

We're ready to run the wizard to fill in your `reference-architecture-form.yml` with valid values.

Before running the wizard, ensure you have completed steps 1, 2 and 3 and that you have the following values ready at hand:

- Personal Access Token for YOUR GitHub user. This token is used to create the Pull Request for the Reference Architecture form.
    - If you do not have one, generate a new Personal Access Token with `repo` level permissions.
- GitHub Machine User Personal Access Token (required in all cases)
- VCS Machine User Personal Access Token (only required if your ultimate infrastructure-live destination is NOT GitHub)
- The HTTPS URL to your VCS `infrastructure-live` repo (e.g., `https://github.com/gruntwork-io/infrastructure-live.git`)
- The SSH URL to your same VCS `infrastructure-live` repo (e.g., `git@github.com:gruntwork-io/infrastructure-live.git`)

In this repo, you will find two scripts:

- [bootstrap_unix.sh](/bootstrap_unix.sh)
- [bootstrap_windows.py](/bootstrap_windows.py)

Both scripts will:

1. Sanity check that you have access to the required organizations.
2. Install the Gruntwork command line tool, which does all the heavy lifting for you
3. Run the Gruntwork wizard for you, which helps you:
   - Provision your AWS accounts
   - Register domains
   - Set up your VCS token secrets
   - Fill in your reference-architecture-form.yml file with valid values
   - Commit and push your form to GitHub and open a pull request

Run the corresponding script based on your platform:

### Linux or Mac OS

```bash
export GITHUB_OAUTH_TOKEN=<YOUR GITHUB PERSONAL ACCESS TOKEN>
./bootstrap_unix.sh
```

### Windows

Install python, and then run:

```
$env:GTIHUB_OAUTH_TOKEN = 'YOUR GITHUB PERSONAL ACCESS TOKEN'
python3 bootstrap_windows.py
```

## Step 5. Iterate on your form and push your changes up to run your Preflight Checks

![Gruntwork Preflight Checks on GitHub](/assets/preflight-checks.png)

Once your form is filled in and pushed to GitHub, our GitHub automations will take over. You'll notice a special GitHub check called _Preflight Checks_ that will run against your `reference-architecture-form.yml` file and flag any errors for you directly in your pull request, like so:

![Gruntwork Preflight Checks](/assets/preflight-checks-preview.png)

You can then locally iterate on your form by editing `reference-architecture-form.yml` on the `ref-arch-form` branch and pushing your changes up to GitHub. Each time you make a new commit and push it, the Gruntwork _Preflight Checks_ will be run against your form.

## Next Steps

Once all your _Preflight Checks_ pass, you can merge your pull request, which will commence your Ref Arch deployment.

Gruntwork engineers are automatically notified of each new Ref Arch deployment, so there's no need to reach out to support just to inform us that your deployment has commenced.

Gruntwork engineers will monitor your deployment and receive notifications about failures and issues that may require intervention to resolve.

Gruntwork engineers rotate through all active deployments to fix up issues preventing them from making forward progress. In general, deployments take "About a day", although there are plenty of variables outside of our control that can occasionally interfere with a deployment, and which may take longer than a day to remediate.

Gruntwork engineers will reach out to you to communicate a status update or next steps if your deployment requires additional intervention to complete.

## Manual setup instructions

<details>
<summary>
Click here if you would like to perform the setup actions manually
</summary>

Visit [the Gruntwork releases page](https://github.com/gruntwork-io/gruntwork/releases)

Find and download the correct binary for your platform.

### Mac and Linux instructions

Mac and Linux users, move it into `/usr/local/bin/`. For example, assuming you downloaded `gruntwork_linux_amd64`:

`sudo mv ~/Downloads/gruntwork_linux_amd64 /usr/local/bin/gruntwork`

Make the binary executable

`chmod +x /usr/local/bin/gruntwork`

Run the setup wizard

`gruntwork wizard`

### Windows users

Download and move your binary to your `C:\Program Files` directory.

Append the full path to your `gruntwork` binary to your system's PATH.

Run the setup wizard

`gruntwork wizard`

</details>

## Frequently Asked Questions (F.A.Q)

<details>
<summary>Click to expand the FAQ section</summary>

_Why do I need to create another repository? Can't I use this repository for my infrastructure code?_

Our Reference Architecture deployment process depends on having access to the code. In lieu of requesting for access to
a repository that you own, we use this current repository in the `gruntwork-clients` GitHub organization to stage the
code for the Reference Architecture deployment.

This code should be moved to a repository that you have full control over once everything is deployed.


_Why do I need a machine user?_

The reference architecture includes an end-to-end [CI/CD pipeline for infrastructure](https://gruntwork.io/pipelines/). You’ll need to set up a _machine user_ (also known as a _service account_) that will automatically checkout your code, push artifacts (such as Docker images and AMIs), and access the Gruntwork IaC Library.

You need one [machine user in GitHub](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) to access the repos in the Gruntwork IaC Library. If you’re not using GitHub, (e.g., in BitBucket or GitLab), you’ll need to create a machine user for that VCS.


_What are the various Ref Arch accounts used for?_

This is the breakdown of AWS accounts in the Reference Architecture:

- **Security**: for centralized authentication to other accounts, including management of IAM users, groups, and roles.
- **Logs**: A log archive account that contains a central Amazon S3 bucket for storing copies of all AWS CloudTrail and AWS Config log files.
- **Shared**: Shared services account for sharing resources such as Amazon Machine Images (AMIs) and Docker images with other accounts. This account can also be used to provide common infrastructure such as monitoring systems (e.g. Grafana) with other accounts.
- **Dev**: A dedicated app account for development purposes, intended to isolate early development releases from the rest of your infrastructure.
- **Stage**: A dedicated app account for hosting staging, testing, and/or QA environments.
- **Prod**: A dedicated app account for production deployments, intended for live environments used by customers.


_Where can I read the Ref Arch Setup FAQ?_

Please find our [Reference Architecture Pre-Deployment FAQ page here](https://docs.gruntwork.io/faq/ref-arch-predeployment/).


_How do I commit and push my form changes?_

Commiting changes and pushing to the remote repository:

```bash
git add reference-architecture-form.yml
git commit -m 'Completed reference architecture form.'
git push origin ref-arch-form
```


_How do I open a pull request with my changes?_

[See the GitHub docs on how to open a pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request).

</details>
