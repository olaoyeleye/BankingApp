# Environment Setup Guide

## Branch → Environment Mapping

| Branch     | Environment | Approval Required | State File Key                            |
|------------|-------------|-------------------|-------------------------------------------|
| `test`     | test        | No                | `banking-app/test/terraform.tfstate`      |
| `dev`      | dev         | No                | `banking-app/dev/terraform.tfstate`       |
| `prod`     | prod        | **Yes**           | `banking-app/prod/terraform.tfstate`      |

## How It Works

1. **Push to a branch** → The `deploy.yml` workflow automatically triggers and deploys to the matching environment.
2. **`test` and `dev` branches** → Deploy immediately without approval.
3. **`prod` branch** → GitHub Environment protection rules require an approval from designated reviewers before the deployment proceeds.

## GitHub Repository Setup (One-Time)

### 1. Create GitHub Environments

Go to your repository on GitHub → **Settings** → **Environments** and create three environments:

#### `test` Environment
- Name: `test`
- No required reviewers (auto-deploy)
- Optional: Add environment-specific secrets if needed

#### `dev` Environment
- Name: `dev`
- No required reviewers (auto-deploy)
- Optional: Add environment-specific secrets if needed

#### `prod` Environment
- Name: `prod`
- **Required reviewers**: Add the users/teams who must approve prod deployments
- **Wait timer**: Optional (e.g., 5 minutes to allow cancellation)
- **Deployment branch**: Select `prod` branch only
- Optional: Add environment-specific secrets (e.g., prod DB credentials)

### 2. Configure Branch Protection Rules

Go to **Settings** → **Branches** → **Branch protection rules**:

#### `prod` Branch Protection
- **Require a pull request before merging**: ✅
- **Require approvals**: ✅ (set minimum, e.g., 1 or 2)
- **Require status checks to pass**: ✅
- **Require branches to be up to date before merging**: ✅
- **Do not allow force pushes**: ✅
- **Do not allow deletions**: ✅

#### `dev` Branch Protection (Recommended)
- **Require a pull request before merging**: Optional (can allow direct pushes)
- **Require status checks to pass**: ✅

#### `test` Branch Protection (Optional)
- Can allow direct pushes for rapid iteration

### 3. Create the Branches

If the branches don't exist yet, create them from the `split` branch:

```bash
git checkout split
git push origin split:test
git push origin split:dev
git push origin split:prod
```

## Terraform State Isolation

Each environment maintains its own Terraform state file in S3:

```
s3://techbleat-bank-application/
  ├── banking-app/test/terraform.tfstate
  ├── banking-app/dev/terraform.tfstate
  └── banking-app/prod/terraform.tfstate
```

This ensures that:
- Infrastructure changes in one environment don't affect others
- Each environment can be destroyed independently
- State files are isolated and encrypted

## AWS Resource Naming Convention

Resources are tagged and named with the environment suffix:

| Resource              | Naming Pattern                           | Example (prod)                        |
|-----------------------|------------------------------------------|---------------------------------------|
| EKS Cluster           | `{vpc_name}-{env}-cluster`               | `tai-key-prod-cluster`                |
| VPC                   | `{vpc_name}-{env}-vpc`                   | `tai-key-prod-vpc`                    |
| Subnets               | `{vpc_name}-{env}-public-a/b`            | `tai-key-prod-public-a`               |
| Security Groups       | `{vpc_name}-{env}-nodes-sg`              | `tai-key-prod-nodes-sg`               |
| EC2 (Nginx)           | `{instance_name}-{env}`                  | `nginx-node-prod`                     |

## Workflows

### Deploy (`.github/workflows/deploy.yml`)
- **Trigger**: Push to `test`, `dev`, or `prod` branches, or manual `workflow_dispatch`
- **Approval**: Required for `prod` environment (via GitHub Environment settings)
- **Actions**: Full infrastructure provisioning + application deployment

### Destroy (`.github/workflows/destroy.yml`)
- **Trigger**: Manual `workflow_dispatch` only (select target environment)
- **Approval**: Required for `prod` environment
- **Actions**: Destroys all infrastructure for the selected environment

## Typical Developer Workflow

```bash
# 1. Create a feature branch from dev
git checkout dev
git checkout -b feature/my-feature

# 2. Make changes and push
git add .
git commit -m "Add my feature"
git push origin feature/my-feature

# 3. Merge to test for testing
git checkout test
git merge feature/my-feature
git push origin test  # → Auto-deploys to test environment

# 4. After testing, merge to dev
git checkout dev
git merge feature/my-feature
git push origin dev   # → Auto-deploys to dev environment

# 5. Create PR to prod (requires approval)
git checkout prod
git merge dev
git push origin prod  # → Waits for approval, then deploys to prod
```

## Using GitHub CLI for Branch Protection

You can also configure branch protection using the GitHub CLI:

```bash
# Install GitHub CLI: https://cli.github.com/

# Login
gh auth login

# Set repo variable
REPO="olaoyeleye/BankingApp"

# Protect prod branch - require PR and approvals
gh api repos/$REPO/branches/prod/protection \
  --method PUT \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field enforce_admins=true \
  --field restrictions=null

# Protect prod branch - require status checks
gh api repos/$REPO/branches/prod/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=true \
  --field restrictions=null