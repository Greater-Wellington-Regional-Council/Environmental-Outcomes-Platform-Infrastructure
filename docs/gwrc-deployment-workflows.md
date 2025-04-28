# GWRC Deployment Workflows

This document outlines the deployment workflows for deploying changes to the Environmental Outcomes Platform (EOP) services. These workflows aim to ensure consistent and reliable deployments while allowing flexibility to adapt to project-specific needs.

## Backend Deployments

### General Workflow

Backend deployments are triggered by changes to the `main` branch of this repository. All changes must be made via a pull request (PR) to the `main` branch. Once the PR is merged, the changes are automatically deployed to the target environment using GitHub Actions.

### Example Deployment Workflow

To deploy changes (e.g., Dependabot updates) to the **Manager** on the **dev envrionment**:

1. Navigate to the `eopdev` folder in this repository.
2. Update the `module_config.hcl` file for the `ecs-eop-manager` service to reference the commit hash of the changes you want to deploy. (See the "Finding the Commit Hash" section below for details.)
3. Create a PR to the `main` branch with the updated `module_config.hcl` file.
4. Once the PR is merged, the changes will be automatically deployed to the **dev environment** via GitHub Actions.

---

### Deployment Workflows

#### Deploying Changes to Non-Production Environments

- **Environments Covered**: Dev, Staging (excludes Prod, `_envcommon`, and shared environments).
- **Process**: PRs can be merged into `main` without peer review to streamline development.

#### Deploying Changes to Production

- **Approval Requirements**: PRs must be reviewed and approved by at least one other developer before merging into `main`.
- **Additional Steps**: Changes must also be PR'd and approved in the `main` branch of the EOP repository.

---

### Finding the Commit Hash for Deployments

When pushing package changes to GitHub in the EOP repository, a container build is triggered. The commit hash of the build corresponds to the changes you want to deploy.

#### How to Retrieve the Commit Hash:
1. **Using Local Git Client**:
   - Run `git log` to view recent commits.
2. **Using GitHub UI**:
   - Navigate to the repository's GitHub Actions page.
   - Locate the relevant build and copy the associated commit hash.

---

## Frontend (Amplify) Deployments

### Overview

Frontend deployments (e.g., Plan Limits UI, CCCV) are managed differently from backend deployments. They do not require changes to the EOP Infrastructure repository. Instead, deployments are triggered directly from the EOP repository.

### Deployment Process

1. Push changes to a **perennial branch** following the naming convention:  
   `deploy/{app-name}/{environment}` (e.g., `deploy/cccv/dev`).
2. Custom deployments can also be initiated via the Amplify UI in AWS.

---

## Notes

- These workflows are intended as guidance and may evolve over time.
- Always ensure proper testing and review processes are followed, especially for production changes.




