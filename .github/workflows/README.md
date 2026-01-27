# Terraform CI/CD Workflow

This directory contains GitHub Actions workflows for automating Terraform infrastructure deployments.

## Overview

The `terraform.yml` workflow provides automated validation, planning, and deployment capabilities for Terraform infrastructure across multiple environments (dev, staging, prod).

## Workflow Features

- **Automated Validation**: Runs on all PRs and pushes to validate Terraform code
- **Environment-Specific Planning**: Generates plans for dev, staging, and prod on PRs
- **PR Comments**: Automatically posts plan output as PR comments for review
- **Manual Deployment**: Workflow dispatch for controlled deployments with approval gates
- **State Management**: Environment-specific state files in S3
- **Artifact Storage**: Plan files saved as artifacts for 5 days

## Workflow Triggers

### Pull Requests
- Triggers validation and planning for all environments
- Posts plan output as PR comments
- Runs on changes to `.tf`, `.tfvars`, or workflow files

### Push to Main/Develop
- Triggers validation only
- Does not run plans or apply changes

### Manual Workflow Dispatch
- Allows manual triggering with environment and action selection
- Requires approval for production environment (via GitHub Environments)

## Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

### AWS Credentials
- `AWS_ACCESS_KEY_ID`: AWS access key for Terraform operations
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for Terraform operations

### Terraform Backend
- `TERRAFORM_STATE_BUCKET`: S3 bucket name for storing Terraform state
- `TERRAFORM_STATE_LOCK_TABLE`: DynamoDB table name for state locking

### Optional: OIDC (Recommended for Production)
Instead of access keys, consider using OIDC for better security:
1. Configure AWS IAM OIDC provider for GitHub
2. Create IAM role with appropriate permissions
3. Update workflow to use `aws-actions/configure-aws-credentials@v4` with OIDC

## GitHub Environments Setup

Configure GitHub Environments in repository settings to enable approval gates:

1. Go to **Settings** → **Environments**
2. Create environments: `dev`, `staging`, `prod`
3. Configure protection rules:
   - **dev**: No protection (optional)
   - **staging**: Optional reviewers
   - **prod**: Required reviewers (recommended)

### Production Environment Protection
For production, configure:
- **Required reviewers**: Add team members who can approve deployments
- **Wait timer**: Optional delay before deployment (e.g., 5 minutes)
- **Deployment branches**: Restrict to `main` branch only

## Environment Configuration

Each environment has its own `.tfvars` file:
- `terraform.dev.tfvars` - Development environment
- `terraform.staging.tfvars` - Staging environment
- `terraform.prod.tfvars` - Production environment

### State File Organization
State files are stored in S3 with environment-specific paths:
- `infra-db/dev/terraform.tfstate`
- `infra-db/staging/terraform.tfstate`
- `infra-db/prod/terraform.tfstate`

## Usage

### Running Validation and Plans (Automatic)
1. Create a pull request with Terraform changes
2. The workflow automatically:
   - Validates code formatting (`terraform fmt -check`)
   - Initializes Terraform
   - Validates configuration (`terraform validate`)
   - Generates plans for all environments
   - Posts plan output as PR comments

### Manual Deployment

1. Go to **Actions** → **Terraform CI/CD**
2. Click **Run workflow**
3. Select:
   - **Environment**: `dev`, `staging`, or `prod`
   - **Action**: `plan` (preview) or `apply` (deploy)
4. Click **Run workflow**
5. For production, approve the deployment when prompted

### Reviewing Plans

- **In PR Comments**: Plan output is posted as collapsible comments
- **As Artifacts**: Download plan files from workflow run artifacts
- **In Workflow Logs**: View full plan output in workflow logs

## Workflow Jobs

### `validate`
- Runs on all triggers
- Checks code formatting
- Validates Terraform configuration
- No AWS credentials required

### `plan-dev`, `plan-staging`, `plan-prod`
- Run on pull requests only
- Generate Terraform plans for each environment
- Post results as PR comments
- Save plan files as artifacts

### `apply`
- Runs on manual workflow dispatch only
- Requires environment selection
- Respects GitHub Environment protection rules
- Applies changes to selected environment

## Best Practices

1. **Always Review Plans**: Review plan output before approving applies
2. **Test in Dev First**: Deploy to dev/staging before production
3. **Use Branch Protection**: Protect main branch with required reviews
4. **Monitor Deployments**: Watch workflow runs for errors
5. **Keep Secrets Secure**: Rotate AWS credentials regularly
6. **Use OIDC**: Prefer OIDC over access keys for better security

## Troubleshooting

### Workflow Fails on Validation
- Check `terraform fmt -check` output for formatting issues
- Run `terraform fmt` locally to fix formatting
- Ensure all `.tf` files are valid Terraform syntax

### Plan Fails
- Verify AWS credentials are correct
- Check S3 bucket and DynamoDB table exist
- Ensure backend configuration matches your setup
- Verify environment-specific `.tfvars` files exist

### Apply Fails
- Check AWS IAM permissions for Terraform operations
- Verify state file is not locked (check DynamoDB)
- Review Terraform error messages in workflow logs
- Ensure environment protection rules are configured correctly

### PR Comments Not Appearing
- Verify `GITHUB_TOKEN` has write permissions (usually automatic)
- Check workflow logs for comment creation errors
- Ensure PR is from a fork (may have permission limitations)

## Security Considerations

- **Never commit secrets**: Keep `.tfvars` files with sensitive data out of version control
- **Use GitHub Secrets**: Store AWS credentials in GitHub Secrets, not in code
- **Enable OIDC**: Use OIDC for production deployments
- **Review Plans**: Always review plan output before applying
- **Limit Access**: Restrict who can approve production deployments
- **Audit Logs**: Review GitHub Actions audit logs regularly

## Related Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [AWS IAM OIDC for GitHub](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

