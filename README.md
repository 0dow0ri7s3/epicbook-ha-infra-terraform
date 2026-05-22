# Epicbook Infrastructure (Terraform & AWS OIDC)

A production-ready Infrastructure-as-Code (IaC) blueprint that automates AWS cloud setup and enables **keyless**, secure deployment pipelines for the Epicbook application using Terraform and GitHub Actions OIDC. 

---

## Why this exists

Using long-lived AWS Access Keys in CI/CD (for example, stored as GitHub Secrets) is a significant security risk because leaked keys can expose your entire AWS account.
Manually creating resources in the AWS Console makes infrastructure hard to reproduce, track, or scale; IaC with Terraform solves these problems by providing repeatable, versioned manifests for provisioning cloud resources.

---

## What this repository provides

- Keyless AWS authentication via GitHub Actions OIDC trust, allowing GitHub to request short-lived AWS credentials without static secrets.
- Automated ECR (Elastic Container Registry) configuration to store and version container images.
- A modular Terraform layout separating environment-specific configs (e.g., dev) from reusable modules (IAM, networking, compute).
- Remote state management using an S3 backend and DynamoDB for state locking to prevent concurrent state corruption.

---

## Features

- Keyless AWS Authentication (OIDC) for secure, token-based GitHub Actions deployments.
- Automated container registry (ECR) provisioning and push permissions.
- Modular, environment-driven structure to support multiple accounts/environments.
- Remote Terraform state with S3 backend and DynamoDB locking.

---

## Tech stack

- Infrastructure as Code: Terraform.
- Cloud: AWS (IAM, ECR, S3, DynamoDB).
- CI/CD: GitHub Actions using OIDC federation.
- Local dev: WSL (Ubuntu) / Linux CLI.

---

## Project layout

```text
epicbook-infra-terraform/
├── environments/
│   └── dev/
│       ├── main.tf          # Provider configs & module calls
│       ├── oidc.tf          # GitHub Actions OIDC provider & trust policies
│       ├── outputs.tf       # Outputs (ECR URLs, role ARNs)
│       ├── terraform.tfvars # Local environment values (DO NOT COMMIT)
│       └── variables.tf     # Environment variable definitions
└── modules/                 # Reusable modules (IAM, ECR, networking, etc.)
```

---

## terraform.tfvars template (DO NOT COMMIT)

Create `environments/dev/terraform.tfvars` with values specific to your environment; do not push this file to GitHub.

Example:

```hcl
aws_region        = "us-east-1"
environment       = "dev"
project_name      = "epicbook"

github_repositories = [
  "repo:0dow0ri7s3/epicbook-app:*",
  "repo:devopenginelab/epicbook-app:*"
]
```

Add `*.tfvars` to `.gitignore` to avoid accidental commits.

---

## Prerequisites

- AWS CLI configured with an account that can create IAM, ECR, S3, DynamoDB resources.
- Terraform installed locally (compatible version with repository modules).
- A `.gitignore` with `*.tfvars` to prevent leaking local secrets.

---

## Quickstart — deploy dev environment

1. Change to the dev environment:
   ```bash
   cd environments/dev
   ```

2. Create your local `terraform.tfvars`:
   ```bash
   nano terraform.tfvars
   ```

3. Initialize Terraform (backend & modules):
   ```bash
   terraform init
   ```

4. Validate configuration:
   ```bash
   terraform validate
   ```

5. Inspect plan:
   ```bash
   terraform plan
   ```

6. Apply (provision resources):
   ```bash
   terraform apply
   ```

Use `terraform plan -out=tfplan` and `terraform apply tfplan` if you want a two-step deploy workflow.

---

## OIDC & GitHub Actions notes

- Create an AWS IAM OIDC provider for GitHub Actions (`token.actions.githubusercontent.com`) and configure an IAM role with an appropriate trust policy that restricts subjects to your repository (for example, `repo:org/repo:*`). This allows GitHub Actions to call STS to assume the role and receive short-lived credentials.
- Scope role permissions carefully (least privilege). Grant only what the workflow needs (for example, S3/DynamoDB for Terraform state, ECR push for container builds).

Example trust condition pattern:

```json
"Condition": {
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:*"
  }
}
```

Incorrect subject strings will break the OIDC handshake; be precise.

---

## Common challenges & lessons

- Syntax errors and duplicated/incorrect arguments in Terraform can break plans (use `terraform validate` and linters).
- Remote state locking requires correct DynamoDB table setup; failed runs can leave locks requiring manual release.
- OIDC policy string matching is strict; a single character mistake in repo claims can prevent role assumption.

---

## Future improvements

- Add separate staging and production accounts with identical Terraform manifests for full environment isolation.
- Extend modules to fully automate compute (ECS/EKS) to run images pushed to ECR automatically.

---

## Author & maintainer

**Odoworitse Afari** — Cloud & DevOps Engineer. Specialized in building, automating, and managing scalable, secure cloud infrastructure. Open to remote contracts and collaborations.

Connect:

- LinkedIn: [Odoworitse](www.linkedin.com/in/odoworitse-afari)
- GitHub: [0dow0ri7s3](https://github.com/0dow0ri7s3)