# Banking App — Multi-Environment CI/CD

## Overview

This project supports **three environments**: `dev`, `test`, and `prod`. Each environment maps to a Kubernetes namespace (`banking-dev`, `banking-test`, `banking-prod`) on a shared EKS cluster.

## Branch Strategy

| Branch     | Environment | K8s Namespace  | Approval Required? |
|------------|-------------|----------------|---------------------|
| `dev`      | dev         | `banking-dev`  | No                  |
| `test`     | test        | `banking-test` | No                  |
| `prod`     | prod        | `banking-prod` | **Yes** (GitHub Environment) |

### How Approval Works

1. In GitHub, go to **Settings → Environments**
2. Create three environments: `dev`, `test`, `prod`
3. For `prod`, enable **Required reviewers** and add the team/users who must approve
4. Developers can freely commit to `dev` and `test` — pushes trigger automatic deployment
5. Commits to `prod` trigger the workflow but pause at the `deploy-helm` job until a reviewer approves

## GitHub Actions Workflows

### `apply.yml` — Application Deployment (triggered on push)
- **Triggers**: Push to `dev`, `test`, or `prod` branch; or manual dispatch
- **Steps**:
  1. Detect environment from branch name
  2. Build & push Docker images (user, transaction, activity, postgres, frontend) to ECR
  3. Deploy via `helm upgrade --install` with environment-specific values
  4. Sync manifest repo to EC2 Nginx instance

### `infra.yml` — Infrastructure Management (manual only)
- **Trigger**: Manual dispatch only
- **Steps**: Terraform init/plan/apply (or destroy) for the shared EKS cluster

### `destroy.yml` — Destroy Application (manual only)
- **Trigger**: Manual dispatch only
- **Steps**:
  1. Uninstall Helm release and delete namespace
  2. Optionally destroy infrastructure (EKS, VPC) if `destroy_infra` is true

## Helm Chart Structure

```
helm/banking-app/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Base/default values
├── values-dev.yaml         # Dev overrides (minimal resources, no TLS)
├── values-test.yaml        # Test overrides (medium resources)
├── values-prod.yaml        # Prod overrides (3 replicas, TLS, high resources)
└── templates/
    ├── _helpers.tpl        # Template helpers (namespace, labels)
    ├── namespace.yaml      # Per-env namespace
    ├── configmap.yaml      # App configuration
    ├── secret.yaml         # App secrets
    ├── postgres.yaml       # Postgres + PVC + init SQL
    ├── redis.yaml          # Redis deployment & service
    ├── kafka.yaml          # Kafka deployment & service
    ├── user-service.yaml   # User service deployment & service
    ├── transaction-service.yaml
    ├── activity-service.yaml
    ├── frontend.yaml       # Frontend deployment & service
    └── ingress.yaml        # Nginx ingress with CORS
```

## Environment Differences

| Setting              | Dev            | Test           | Prod                     |
|----------------------|----------------|----------------|--------------------------|
| Replicas (app)       | 1              | 2              | 3                        |
| Postgres storage     | 5Gi            | 10Gi           | 20Gi                     |
| TLS                  | No             | No             | Yes                      |
| Ingress host         | (ALB hostname) | (ALB hostname) | bank.yourdomain.com      |
| Datadog              | Disabled       | Enabled        | Enabled                  |
| Hibernate DDL        | update         | update         | none                     |

## Required GitHub Secrets

| Secret                     | Description                         |
|----------------------------|-------------------------------------|
| `AWS_ACCESS_KEY_ID`        | AWS access key                      |
| `AWS_SECRET_ACCESS_KEY`    | AWS secret key                      |
| `AWS_REGION`               | AWS region (e.g., `us-east-1`)      |
| `AWS_ACCOUNT_ID`           | AWS account ID                      |
| `VPC_NAME`                 | VPC/cluster name prefix             |
| `AMI_ID`                   | EC2 AMI ID                          |
| `INSTANCE_TYPE`            | EC2 instance type                   |
| `INSTANCE_NAME_NGINX`      | Nginx instance name                 |
| `KEY_NAME`                 | SSH key pair name                   |
| `EKS_ADMIN_PRINCIPAL_ARN`  | EKS admin principal ARN             |
| `ANSIBLE_SSH_PRIVATE_KEY`  | SSH private key for Ansible         |
| `DATADOG_API`              | Datadog API key (optional)          |
| `DATADOG_APP`              | Datadog app key (optional)          |

## Terraform

Terraform manages the **shared infrastructure** (single EKS cluster, VPC, EC2 Nginx instance, ECR repositories). It is environment-agnostic — all environments share the same cluster and deploy into separate namespaces.

## Ansible

The Ansible playbook (`ansible/playbook.yml`) configures the EC2 Nginx instance with:
- AWS CLI, kubectl, Helm
- EKS kubeconfig
- ingress-nginx controller
- Datadog operator

Application deployment is handled by Helm in the GitHub Actions workflow.

## Quick Start

1. **Set up GitHub Environments** (Settings → Environments): create `dev`, `test`, `prod`. Add required reviewers to `prod`.
2. **Add GitHub Secrets** (see table above)
3. **Run Infrastructure workflow** manually (`infra.yml`) to provision EKS
4. **Push to `dev` branch** to deploy the app to the dev environment
5. **Push to `test` branch** to deploy to test
6. **Push to `prod` branch** → approval will be requested before deployment