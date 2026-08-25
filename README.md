# EpicBook — Highly Available AWS Infrastructure with Terraform

A three-tier, multi-AZ AWS environment provisioned entirely as code. Public-facing load
balancer, application servers in private subnets behind an Auto Scaling Group, and a
managed MySQL database that is not reachable from the internet at all.

Built as part of a structured DevOps engineering programme, then debugged and extended
independently.

---

## The problem

A typical single-instance deployment puts the web server, the application and the
database on one EC2 box with a public IP. It works until it doesn't:

- One instance dies and the whole application is down
- The database is exposed to the internet on a public IP
- Scaling means resizing the instance and taking downtime
- Rebuilding means repeating console clicks and hoping you remember every step

This repository solves those four problems with a layered network, an Auto Scaling
Group across two availability zones, a database in isolated private subnets, and
Terraform modules that make the whole environment reproducible.

---

## Architecture

```
                            Internet
                                │
                                ▼
                   ┌────────────────────────┐
                   │  Application Load      │   Public subnets
                   │  Balancer (ALB)        │   AZ-a  ·  AZ-b
                   └────────────┬───────────┘
                                │  only ALB SG may reach app tier
                                ▼
                   ┌────────────────────────┐
                   │  Auto Scaling Group    │   Private app subnets
                   │  EC2 · Node.js · PM2   │   AZ-a  ·  AZ-b
                   └────────────┬───────────┘
                                │  only App SG may reach database
                                ▼
                   ┌────────────────────────┐
                   │  RDS MySQL             │   Private DB subnets
                   │                        │   AZ-a  ·  AZ-b
                   └────────────────────────┘
```

**Public subnets** hold only the load balancer. **Private application subnets** hold the
EC2 instances — they have no public IP and are reachable only through the ALB. **Private
database subnets** hold RDS, reachable only from the application tier.

---

## Repository layout

```
environments/
  dev/
    main.tf          # backend config, providers, module wiring
    oidc.tf          # GitHub Actions OIDC provider and IAM role
    variables.tf
    outputs.tf
modules/
  network/           # VPC, subnets, route tables, gateways
  security_groups/   # ALB, application and database security groups
  compute/           # launch template, Auto Scaling Group, ALB, target group
  rds/               # MySQL instance, subnet group, parameter config
```

The split between `environments/` and `modules/` means a staging or production
environment is a new directory with different variable values, not a copy-paste of the
whole stack.

---

## Stack

| Layer | Technology |
|---|---|
| Infrastructure as code | Terraform (`>= 1.0.0`) |
| Cloud | AWS — VPC, EC2, ALB, Auto Scaling, RDS MySQL, IAM, S3 |
| Application runtime | Node.js, PM2 |
| CI/CD authentication | GitHub Actions with OIDC |
| State | S3 backend with state locking |

---

## Key decisions

### 1. Security groups reference each other, not CIDR ranges

Each tier's security group allows traffic only from the security group above it:

- **ALB SG** — accepts 80/443 from the internet
- **App SG** — accepts traffic only from the ALB's security group ID
- **RDS SG** — accepts 3306 only from the application's security group ID

Nothing between tiers is allowed by IP range. That means the database cannot be reached
directly even from another resource inside the same VPC, and it stays true when instances
are replaced by the Auto Scaling Group and get new private IPs. A CIDR-based rule would
break, or would have to be written so wide that it stopped protecting anything.

### 2. GitHub Actions authenticates with OIDC, not access keys

`oidc.tf` provisions an IAM OIDC identity provider for GitHub and a role that Actions
workflows assume at runtime.

The alternative — generating an IAM user, creating long-lived access keys, and storing
them as repository secrets — means a permanent credential that exists whether or not a
workflow is running, has to be rotated manually, and is compromised forever if it leaks.
OIDC issues a short-lived token scoped to a specific repository, and there is no static
secret to leak.

### 3. Remote state in S3 with locking

State lives in an S3 bucket with locking enabled rather than on a local machine.

Local state means the file exists on exactly one laptop, cannot be shared, and offers no
protection against two applies running at once. Locking prevents concurrent applies from
corrupting state — which matters the moment more than one person, or a CI pipeline,
touches the same environment.

### 4. Security groups are their own module

Most examples fold security groups into the network module. Keeping them separate means
the rules can be read in one place as a single access-control policy, rather than being
scattered through the resources they attach to. When the question is "what can reach the
database," the answer is in one file.

---

## How to run

**Prerequisites:** Terraform >= 1.0.0, AWS CLI configured with credentials, and an
existing S3 bucket for state.

```bash
git clone https://github.com/0dow0ri7s3/epicbook-ha-infra-terraform.git
cd epicbook-ha-infra-terraform/environments/dev
```

Set the backend values in `main.tf` to your own bucket, then:

```bash
terraform init
terraform plan
terraform apply
```

Outputs include the ALB DNS name — the application is reachable there once instances pass
health checks.

**Tear down:**

```bash
terraform destroy
```

RDS may take several minutes. Check the console afterwards to confirm nothing is left
running.

---

## Troubleshooting log — the database that was connected but not reachable

After deploying the infrastructure and the EpicBook application, the application could
not read from the database. The error pointed at the database connection.

**Step 1 — check the obvious infrastructure cause.**
The first hypothesis was a misconfigured security group, since that is the most common
reason an application cannot reach RDS. Reviewed the chain: ALB to app, app to database,
port 3306. The rules were correct.

**Step 2 — test the connection directly.**
Rather than continuing to edit infrastructure, I connected to the database manually from
the EC2 instance. **It connected.**

This is the step that made the rest of the work straightforward. A successful manual
connection proves the network path, the security groups, the subnet routing and the
credentials are all working — which eliminates the entire infrastructure layer in a
single test. The fault had to be in the application.

**Step 3 — verify the database name against the data, not the docs.**
The project's setup instructions specified a database named `epicbook`. Checking the SQL
dump files, the actual database name was `bookstore`. The documentation was out of date
and I had created the database from the documentation. Recreated it with the correct name.

Still not connecting.

**Step 4 — get the logs.**
The application was running under PM2 in the background, so the failure was not visible in
the terminal. Reading the PM2 crash logs pointed into the application's configuration file.

**Step 5 — root cause.**
The setup instructions said to create a `.env` file in the project root with the database
credentials, and the application would pick them up automatically. It did not. The config
file had the connection values hardcoded and never read `.env` at all.

**Fix.** Rewired the config to read credentials from the environment rather than from
hardcoded values.

### What this failure teaches

The error message said "database connection." The infrastructure was correct throughout,
and the actual fault was in application configuration — two layers away from where the
symptom appeared.

Two things made it findable. Testing the connection manually cut the search space in half
in one move. And treating the project's own documentation as a claim to verify, rather
than a fact to trust, surfaced the second bug hiding underneath the first.

---

## What I would improve

**Pin the AWS provider version.** `required_version` constrains Terraform itself, but there
is no `required_providers` block, so a new provider release could change behaviour between
applies without anything in the repository changing.

**Add staging and production environments.** Only `environments/dev` exists. The module
structure supports more, but they are not built yet.

**Move database credentials into AWS Secrets Manager.** They currently pass through
variables. Secrets Manager with rotation would be the correct pattern.

**Add HTTPS on the ALB.** The listener currently serves HTTP. Production would need ACM
and a redirect from 80 to 443.

**Add a CI plan step.** OIDC is configured, but the pipeline does not yet run
`terraform plan` on pull requests, which is where the OIDC role would earn its place.

---

## Note on origin

The EpicBook application and the initial infrastructure requirements come from a
structured DevOps engineering programme. The Terraform module structure, the security
group design, the OIDC configuration and the troubleshooting above are my own work.

---

**Built by [Odoworitse Afari](https://github.com/0dow0ri7s3)** — Cloud & DevOps Engineer.
If something in your AWS deployment is failing and you want a second pair of eyes, my
contact details are on [my profile](https://github.com/0dow0ri7s3).
