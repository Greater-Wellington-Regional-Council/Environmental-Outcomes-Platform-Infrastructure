# Environmental Outcomes Platform (EOP) Infrastructure

This repository contains code to deploy the EOP infrastructure across all live environments in AWS. All the
infrastructure in this repo is managed as **code** and deployed via merging code changes into the **main** branch of
this repo. As such there should be few times that changes need to be made via click-ops in the AWS console, other than
helping with development.  

In fact, even the code in this repository only needs to change if the Infrastructure in AWS on which the various EOP components rely needs to be altered.  If you are adding a front end application or API to Ha Kākano, for example, that affects AWS resources or needs new resources, then you will likely make and test the changes locally first and then modify this repo to update the Infrastructure as Code through a pull request.

This code is built from the [Gruntwork Reference Architecture](https://gruntwork.io/reference-architecture/) using
services from the [Gruntwork
AWS Service Catalog](https://github.com/Greater-Wellington-Regional-Council/gwio_terraform-aws-service-catalog). There is supporting documentation
in the `./docs` folder of this repo, which was initially provided by Gruntworks during the reference architecture setup,
which is useful but quite generic, it will be updated over time to be more specific to EOP.

Here's a diagram that shows a rough overview of what the Reference Architecture looks like:

![Reference Architecture](docs/images/landing-zone-ref-arch.png?raw=true)

## Using this Repository

The code in this repo describes the active installation of EOP currently shared by all contributing parties.  In the event you might want to create and host your own instance somewhere, you can of course fork the repository and modify that freely. However to modify the existing shared infrastructure, for example to support a new API or front end you have developed, you need to complete the following one-time steps:-
* Contact the EOP technical team and have yourself added to the EOP developers group in Github
* Add your email to the AWS account by modifying [this file](https://github.com/Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure/blob/main/security/_global/account-baseline/users.yml) through a pull request
* Set up the [AWS command line application](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) on a development machine so that you can authenticate with the AWS account to check/test any changes you make (see instructions below after downloading and installing)
* Ensure that you can connect to the EOP Bastion Hosts over SSH from your development machine, also for checking/testing

Detailed instructions follow for the above steps. Having completed them, you are in a position to contribute to the existing infrastructure as described [here](#Contributing).

### AWS Account

First you need an IAM user in AWS that provides access to. We do this by creating a IAM user in our "security" account
which then has access to assume roles in the other accounts.

* Create a PR which adds a user to this file `security/_global/account-baseline/users.yml` with the appropriate
  permissions
* Once the PR is merged and deployed. An admin user will need to create a temporary password for you, set to force a new
  one to be created on next login
* Once you have this:
    1. login to [here](https://063810897000.signin.aws.amazon.com/console) with the temp password and
    2. Reset the password
    3. Enable MFA

**Enabling MFA is required in the Reference Architecture**. Without MFA, you will be able to log in, but will not be
able to access anything!

You will now be logged into the security account, to access the other accounts in EOP is done by "switching role" to the
other accounts with specific access.

**Roles which are allowed** (to be used in `.aws/config` as per Local Machine Setup below)

* **allow-read-only-access-from-other-accounts** - Provides read only access to most things
* **allow-dev-access-from-other-accounts** - Provides access intended for developers, the ability to make changes in the
  common AWS services
* **allow-support-access-from-other-accounts** - Provides access that can interact with AWS support
* **allow-billing-only-access-from-other-accounts** - Provides access for people only interested in billing details
* **allow-full-access-from-other-accounts** - Provides unlimited access
* **allow-auto-deploy-from-other-accounts** - Intended for machine users, special role which provides access for our
  auto deployment tasks limiting the scope of what they can do

> Note: Exactly what these roles can do is configurable, and will need to be updated as new AWS services are used.

**Shortcuts for read-only access to other accounts**

* [Shared](https://signin.aws.amazon.com/switchrole?account=898449181946&roleName=allow-read-only-access-from-other-accounts&displayName=Shared_RO)
* [Logs](https://signin.aws.amazon.com/switchrole?account=972859489186&roleName=allow-read-only-access-from-other-accounts&displayName=Logs_RO)
* [Dev](https://signin.aws.amazon.com/switchrole?account=657968434173&roleName=allow-read-only-access-from-other-accounts&displayName=Dev_RO)
* [Stage](https://signin.aws.amazon.com/switchrole?account=564180615104&roleName=allow-read-only-access-from-other-accounts&displayName=Stage_RO)
* [Prod](https://signin.aws.amazon.com/switchrole?account=422253851608&roleName=allow-read-only-access-from-other-accounts&displayName=Prod_RO)

> Note: Each of these will let you choose a color for the particular access, green is good for read only. Most of the
> time read-only access should suffice.

### Local Machine Setup

Now you have access to the AWS account, we recommend that you enable AWS command line access for making Terraform changes
locally and avoiding clicking around the AWS UI.

* Create Access Keys for your account in AWS IAM
  
* Install the [AWS command line application](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [aws-vault](https://github.com/99designs/aws-vault#installing).
  
* Add your IAM User credentials to `.aws/config` as follows.  This is a generated example, so replace `<IAM User>` and
  **allow-full-access-from-other-accounts** with the correct user name and role for you.  Select an appropriate role name from the list of roles above.

```
[default]
region=ap-southeast-2

[profile security]
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>

[profile eopdev]
source_profile = security
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>
role_arn = arn:aws:iam::657968434173:role/allow-full-access-from-other-accounts

[profile eopprod]
source_profile = security
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>
role_arn = arn:aws:iam::422253851608:role/allow-full-access-from-other-accounts

[profile eopstage]
source_profile = security
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>
role_arn = arn:aws:iam::564180615104:role/allow-full-access-from-other-accounts

[profile logs]
source_profile = security
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>
role_arn = arn:aws:iam::972859489186:role/allow-full-access-from-other-accounts

[profile shared]
source_profile = security
mfa_serial = arn:aws:iam::063810897000:mfa/<IAM User>
role_arn = arn:aws:iam::898449181946:role/allow-full-access-from-other-accounts
```

* Configure aws-vault.  See [here for aws-vault installation and setup details](https://github.com/99designs/aws-vault).

* Run the following command to add the security profile credentials to aws-vault 
```
aws-vault add security
```
* If you are working on a mac, you may need to explicitly open your Mac's Keychain Access application at this point and add the aws-vault keychain.  One way you'll recongnise that you need to do this if aws-vault prompts for a password, but will not accept the correct password which you assigned in the last step.  Another indicator is that there is no aws-vault under Custom Keychains in the Keychain Access app.  Open the Keychain Access app, select File/Add Keychain and select the aws-vault.keychain-db file in the resulting dialog to add it.  If added successfully, it should now appear in the app under **Custom Keychains**.

* Once configured, you can use AWS Vault with Terragrunt, Terraform, the AWS CLI, and anything else that uses the AWS
  SDK to authenticate. To check if your authentication is working, you   can run `aws sts caller-identity`

```
aws-vault exec eopdev -- aws sts get-caller-identity
```

* You can also use `aws-vault` to log in to the web console for each account:

```
aws-vault login eopdev --duration 8h -s
```

### SSH Bastion

The config of the systems mean that none of the machines running in AWS are directly accessible from the internet. To be
able to access them, there is a Bastion host with SSH that is connected to the VPC and has routes enabled to key
services (EC2 instances, databases ... )

The Gruntwork config has automatically hardened the bastion host, and made access available for IAM users in the correct
group using their AWS SSH keys.

* Add SSH keys to your account
* usernames are changed to avoid special characters e.g. `john.doe@gw.govt.nz` => `john_doe`
* ssh into the appropriate bastion. e.g. for dev

```bash
ssh john_doe@bastion.gw-eop-dev.tech
```

> Note: for access to database servers this can be done via a SSH tunnel.

### Contributing

Changes to the infrastructure are deployed using the trunk based workflow. That is any change to main will trigger a
github actions workflow which will run the changes into the live environment.

Basic outline:

1. pull latest code to your machine
2. create a branch from `main` for your changes
3. make / commit the changes
    1. Push your changes
    2. this will trigger a Github actions job which will plan what changes will be made when the code is merged
    3. Create a “pull request”
4. Validate what will be changed, discuss and review code
5. "Merge" your branch to the main branch
6. Validate changes are applied successfully

> Note: Be careful when changing things that are shared across environments. If you need to change something shared, it
> will probably need to be factored in such a way that it can be applied to a single environment at a time.

> Note: removing resources completely can't be done via the Github Actions process

## Learn

### Gruntwork Reference Docs

* [How to Build an End to End Production-Grade Architecture on AWS](https://blog.gruntwork.io/how-to-build-an-end-to-end-production-grade-architecture-on-aws-part-1-eae8eeb41fec):
  A blog post series that discusses the basic principles behind the Reference Architecture.
* [How to use the Gruntwork Infrastructure as Code Library](https://gruntwork.io/guides/foundations/how-to-use-gruntwork-infrastructure-as-code-library/):
  The Service Catalog is built on top of the [Gruntwork Infrastructure as Code
  Library](https://gruntwork.io/infrastructure-as-code-library/). Check out this guide to learn what the library is and
  how to use it.
* [Gruntwork Production Deployment Guides](https://gruntwork.io/guides/): Additional step-by-step guides that show you
  how to go
  to production on top of AWS.

## Support

If you need help with this repo or anything else related to infrastructure or DevOps, Gruntwork offers [Commercial
Support](https://gruntwork.io/support/) via Slack, email, and video conference. If you have questions, feel free to
email us at [support@gruntwork.io](mailto:support@gruntwork.io).
