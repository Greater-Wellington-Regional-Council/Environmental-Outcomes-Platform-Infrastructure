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

## Getting Started

If you are not currently a member of the EOP delivery team in GitHub and would like to make changes, you can either fork the repository and submit a PR from your fork, or request that you be added to the EOP group on GitHub and create a new branch and PR containing your changes.  Again, this is only needed if you need/want to change the EOP infrastructure.  In any case, it is likely you will need to to check and test yur changes in AWS before submitting your PR.  To gain access to non-production accounts in AWS for this purpose, you will need to do the following:-
* Add your details to [this file](https://github.com/Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure/blob/main/security/_global/account-baseline/users.yml) via a pull request
* Set up the AWS CLI on your development machine so that you can authenticate with the AWS account
* Ensure you can connect to the Bastion Hosts from your development machine if required (for example, if you are developing a front end module you need to test against your AWS changes)

Detailed instructions follow.  

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

**Roles which are allowed**

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

Now you have access to the AWS account, you may want AWS command line access. This would be for making Terraform changes
locally or just avoiding clicking around the UI in favour of command line tools.

* Create Access Keys for your account
* [Install aws-vault](https://github.com/99designs/aws-vault#installing).
* Add your IAM User credentials:

```
aws-vault add security
```

* Add new profiles for each of the accounts to `~/.aws/config`. This is a generated config, update the <IAM User> and
  role accordingly

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

* Once configured, you can use AWS vault with Terragrunt, Terraform, the AWS CLI, and anything else that uses the AWS
  SDK to authenticate. To check if your authentication is working, you can run `aws sts caller-identity`

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
