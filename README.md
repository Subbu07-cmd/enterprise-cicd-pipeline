# Enterprise CI/CD Pipeline Modernization

> **About this repo:** my production work lives in private enterprise repositories, so this is a public reference build of the same patterns, written from scratch with sample data and placeholder account IDs.

A production-style delivery pipeline for a containerized service on AWS. It shows how to take an application from commit to **dev → staging → prod** with **GitHub Actions** (plus an equivalent **Jenkinsfile**), **reusable Terraform modules** and **security gates** (SAST, SCA, IaC and container scanning) that block a release when they find problems.

```
 PR / push
    │
    ▼
┌────────┐  ┌────────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  lint  │─▶│ unit tests │─▶│ SAST (Bandit)│─▶│ SCA       │─▶│ IaC scan │─▶│ build +  │─▶│ deploy   │
│ (ruff) │  │  (pytest)  │  │              │  │(pip-audit)│  │(Checkov) │  │ Trivy    │  │dev→stg→prd│
└────────┘  └────────────┘  └──────────────┘  └───────────┘  └──────────┘  └──────────┘  └──────────┘
                                                                                          (prod needs
                                                                                           approval)
```

## What's inside

| Path | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Lint, test and security gates on every PR |
| `.github/workflows/deploy.yml` | Build and push to ECR, then promote through `dev`, `staging` and `prod` GitHub Environments using AWS OIDC (no long-lived keys) |
| `.github/workflows/terraform.yml` | `fmt`, `validate`, Checkov and `plan` for each environment |
| `Jenkinsfile` | The same pipeline for Jenkins shops |
| `terraform/modules/*` | Reusable `network`, `ecr`, `eks` and `rds` modules |
| `terraform/envs/{dev,staging,prod}` | Thin environment roots; each environment's sizing lives in its `variables.tf` defaults |
| `app/` | Sample FastAPI service that the pipeline ships |
| `k8s/` | Kubernetes Deployment and Service manifests |

## Design principles

- **Build once, promote many**: one immutable image digest moves through every environment
- **Security as a gate, not a report**: any HIGH or CRITICAL finding fails the build
- **Keyless cloud access**: GitHub OIDC assumes a per-environment IAM role
- **DRY infrastructure**: environments differ only in their variable values
- **Auditable**: every change goes through a PR plan, an approval and an apply

## Issues I hit

The first CI run failed the **Checkov** gate on the RDS and network modules. That's the gate doing its job. Fixes:

| Check | Finding | Fix |
|------|---------|-----|
| CKV2_AWS_30 | No Postgres query logging | Custom parameter group with `log_statement = ddl` and `log_min_duration_statement = 1000` (plus `rds.force_ssl = 1`) |
| CKV_AWS_118 | No enhanced monitoring | `monitoring_interval = 60` with a dedicated monitoring IAM role |
| CKV_AWS_354 | Performance Insights not on a CMK | Module-owned KMS key (rotation on) for storage and Performance Insights |
| CKV_AWS_293 | Deletion protection off in dev | Always on; turned off deliberately only for a planned teardown |
| CKV_AWS_23 | Security group missing a description | Added |
| CKV_AWS_394 | AZ data source can silently expand | AZs pinned via an `azs` variable |
| CKV_AWS_157 | Multi-AZ off in dev/staging | **Accepted risk**: documented `checkov:skip` because prod is Multi-AZ and lower environments stay single-AZ for cost |

Other CI fixes: pytest needed `pythonpath = ["."]` to import the app, the Trivy step now runs the pinned `aquasec/trivy` image, and the deploy workflow skips cleanly until AWS variables are configured.

## Run locally

```bash
pip install -r requirements.txt
pytest -q
uvicorn app.main:app --reload
```

```bash
cd terraform/envs/dev
terraform init && terraform plan
```

## Required GitHub configuration

| Name | Type | Example |
|------|------|---------|
| `AWS_ACCOUNT_ID` | variable | `123456789012` |
| `AWS_REGION` | variable | `us-east-1` |
| `dev`, `staging`, `prod` | environments | add required reviewers to `prod` |

## Tech

GitHub Actions · Jenkins · Terraform · AWS (EC2, EKS, RDS, S3) · Docker · Kubernetes · Checkov · Python
