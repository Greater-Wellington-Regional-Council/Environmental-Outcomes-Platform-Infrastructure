# Quick Start

Congratulations, your Reference Architecture is deployed! You can find all the code, configuration, and documentation in this repository. You can model your own deployments on this pattern.

## Check out the sample apps
- [https://gruntwork-sample-app.gw-eop-dev.tech](https://gruntwork-sample-app.gw-eop-dev.tech)
- [https://gruntwork-sample-app.gw-eop-stage.tech](https://gruntwork-sample-app.gw-eop-stage.tech)
- [https://gruntwork-sample-app.gw-eop-prod.tech](https://gruntwork-sample-app.gw-eop-prod.tech)

## Reference Architecture basics
Here’s some important information about the Gruntwork reference architecture:

1. No Terraform code to maintain! The entire architecture is defined in [Terragrunt configuration files](https://terragrunt.gruntwork.io/).
1. It uses the [Service Catalog](https://github.com/gruntwork-io/aws-service-catalog), a collection of services that are higher level abstractions over our library modules, rather than using the core library modules directly. Again, this eliminates the need to maintain 10s of thousands of lines of Terraform code!
1. We've included the [ecs-deploy-runner](https://github.com/gruntwork-io/module-ci/blob/main/modules/ecs-deploy-runner/README.adoc), our CI / CD pipeline for infrastructure, so that you can use CI / CD to run infrastructure deployments.
1. The accounts are managed with the [Gruntwork Landing Zone](https://gruntwork.io/guides/foundations/how-to-configure-production-grade-aws-account-structure) solution. This includes many cross-account configurations for managing a multi-account environment, such as AWS Config, GuardDuty, and CloudTrail.
1. Many other services have been updated and improved.

# Your next steps

## 1. Migrate the repo - Done
To make it easier to deploy the Reference Architecture, we initially host the code in the https://github.com/gruntwork-clients/infrastructure-live-greater-wellington-regional-council.git repository for you. However, once deployed, you should migrate the code to an `infrastructure-live` repository in your own version control system. The best way to do this is by switching the remote url. For example, if you're using GitHub:

    git clone https://github.com/gruntwork-clients/infrastructure-live-greater-wellington-regional-council.git infrastructure-live
    cd infrastructure-live
    git remote set-url origin https://github.com/Greater-Wellington-Regional-Council/Environmental-Outcomes-Platform-Infrastructure.git
    git push origin main

## 2. Secure each account's root user - Done
Be sure to enable MFA ([instructions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html#enable-virt-mfa-for-root)) on the root user each AWS account, as the root user can bypass just about any other security restrictions you put in place. You can find more info in our [Gruntwork Security Best Practices doc](https://docs.google.com/document/u/1/d/e/2PACX-1vTikva7hXPd2h1SSglJWhlW8W6qhMlZUxl0qQ9rUJ0OX22CQNeM-91w4lStRk9u2zQIn6lPejUbe-dl/pub).

## 3. Login as your IAM user - Done (via click-ops)
Now that you've locked down the root users, you'll need to login as your IAM user. The IAM users live in the **security account**.

* Your PGP encrypted IAM User password is located in [`ADMIN_IAM_USER_PASSWORDS`](./ADMIN_IAM_USER_PASSWORDS) at the root of this repo.
* This blob is PGP encrypted with your Keybase private key and then base64 encoded.
* To turn it into your password using Keybase:
    ```
    echo "<paste your blob>" | base64 --decode | keybase pgp decrypt
    ```
* Alternatively, you may also be able to use your machine's gpg keys to decrypt, if Keybase doesn't work:
    ```
    echo "<paste your blob>" | base64 --decode | gpg --decrypt
    ```
* If none of the above work, there is an escape hatch:
    * The person at your organization who set up the AWS accounts initially should have the root user credentials to
    the security account. This user can use the [Gruntwork CLI](https://github.com/gruntwork-io/gruntwork) to reset
    their password and assist everyone else. Using the root user credentials, they can run:
        ```
        aws-vault exec <SECURITY_ACCOUNT_ROOT_USER_PROFILE> -- gruntwork aws reset-password <IAM_username> <password>
        ```
    * As a fallback, this person can also use click-ops to reset passwords:
        * Navigate to the AWS Console UI
        * Login as the root user of the security account
        * Navigate to the IAM Users administration
        * Find the IAM user in the list of users
        * Reset the user's password
* Once you've set up your AWS access key and secret for your IAM user, you can use them to authenticate to the AWS CLI,
  the [Gruntwork CLI](https://github.com/gruntwork-io/gruntwork), and `terragrunt`/`terraform` in case you need to run
  commands against your AWS accounts locally. Peruse the [authentication documentation](./docs/02-authenticate.md) for
  more details.

### Resetting your password

Going forward, if you ever need to reset your IAM User password, we've provided a convenience in the
[Gruntwork CLI](https://github.com/gruntwork-io/gruntwork). This only works once you have AWS access key and secret set
up locally.

* Run `gruntwork aws reset-password <IAM_username> <password>`.
    * This option requires being authenticated to AWS.
    * With `aws-vault` the full command is `aws-vault exec <profile> -- gruntwork aws reset-password <IAM_username>
    <password>`. Read more about this in the [authentication documentation](./docs/02-authenticate.md).

* As a fallback, the click-ops option is to navigate to the AWS Console UI, login as your IAM user into the security
  account, navigate to the IAM Users page, find your IAM user, and reset your password.

## 4. Revoke Gruntwork access - Done
We recommend that you revoke Gruntwork's access from your Git repos and AWS accounts. To do this, use the `gruntwork aws revoke` command of the [Gruntwork CLI](https://github.com/gruntwork-io/gruntwork).

## 5. Follow the guides in the documentation
Now that you've done all the administrative work, it's time to start using the Reference Architecture. We've written up [some walkthroughs to get you started](./docs/01-overview.md). To start with, you'll need to learn how to:
* [Authenticate to AWS from your machine](./docs/02-authenticate.md)
* [Deploy your apps](./docs/04-deploy-apps.md)
* [Configure your CI / CD pipeline with a Slack integration](./docs/03-configure-gw-pipelines.md)
* [Leverage monitoring, alerting, and logging](./docs/05-monitoring-alerting-logging.md)

Plus some bonus walkthroughs describing how to:
* [Add new AWS accounts](./docs/06-adding-a-new-account.md)
* And even [tear down the architecture](./docs/07-undeploy.md)

### Caveats
You'll notice a [vars/autogen](./vars/autogen) directory. This contains the variable data that we used to generate the architecture from templates. The repository containing the templates is known as terraform-aws-architecture-catalog, and you will have access to this repository soon. In the meantime, you do not need to do anything with this directory.

## Support
If you need help with this repo, [post a question in our knowledge base](https://github.com/gruntwork-io/knowledge-base/discussions?discussions_q=label%3Ar%3Aterraform-aws-architecture-catalog)
or [reach out via our support channels](https://docs.gruntwork.io/support) included with your subscription. If you’re
not yet a Gruntwork subscriber, [subscribe now](https://www.gruntwork.io/pricing/).
