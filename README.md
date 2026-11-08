# Mini Project 2.2: Infrastructure as Code (IaC) for Staging Environment

## 1. IaC Tool Selection & Justification

**Selected Tool:** HashiCorp Terraform

**Justification:**

- **Declarative State Management:** Unlike imperative configuration management tools like Ansible, Terraform maintains a state file (`terraform.tfstate`) that tracks exact resource lifecycle mappings, helping prevent configuration drift between staging and production.

- **Cloud & Provider Agnostic:** Unlike AWS CloudFormation, which locks infrastructure strictly to AWS, Terraform supports multiple cloud providers and local container providers such as `kreuzwerker/docker`. This allows consistent HCL patterns to run locally during testing, in CI/CD runners, and in cloud staging environments.

- **Modularity & Parameterization:** Terraform separates input variables (`variables.tf`), environment-specific values (`staging.tfvars`), and resource declarations (`main.tf`). Sensitive secrets can be injected dynamically at runtime using environment variables such as `TF_VAR_db_password`, avoiding hard-coded credentials.

---

## 2. Infrastructure Architecture Diagram

The following diagram illustrates the staging infrastructure running on a host or CI runner machine using an isolated Docker bridge network.

```text
+-----------------------------------------------------------------------+
|                        Host / CI Runner Machine                       |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |       Isolated Docker Bridge Network (staging_app_tier_net)     |  |
|  |                                                                 |  |
|  |   +-----------------------------+      +--------------------+   |  |
|  |   |     Application Server      |      |   Database Server  |   |  |
|  |   |     (nginx:stable-alpine)   |----->| (postgres:15-alpine)|  |  |
|  |   |  Container: staging_app     |      | Container:         |   |  |
|  |   |  Internal Port: 80          |      | staging_postgres_db|   |  |
|  |   +--------------+--------------+      +---------+----------+   |  |
|  |                  |                               |              |  |
|  +------------------|-------------------------------|--------------+  |
|                     | Port Mapping                  | Port Mapping    |
|                     v (8085:80)                     v (5439:5432)     |
+---------------------|-------------------------------|-----------------+
                      |                               |
              http://localhost:8085          localhost:5439 (PostgreSQL)
```

### Access Points

| Service | Host Address | Container Port | Host Port |
|---|---|---:|---:|
| Application (Nginx) | `http://localhost:8085` | 80 | 8085 |
| PostgreSQL Database | `localhost:5439` | 5432 | 5439 |

### Provisioned Components

1. **Networking Layer (`docker_network.staging_network`):** Creates an isolated bridge network (`staging_app_tier_net`) so the application server and database can communicate internally via DNS container names while remaining isolated from external networks.

2. **Database Layer (`docker_container.staging_db`):** Provisions a PostgreSQL 15 instance injected with parameterized credentials (`db_name`, `db_user`, and runtime environment secret `TF_VAR_db_password`) and attached to the staging network.

3. **Application Server Layer (`docker_container.staging_app`):** Provisions an Nginx application server bound to the staging network with an explicit dependency (`depends_on`) on the database container to guarantee startup ordering.

---

## 3. Version Control & Branching Strategy

Infrastructure changes follow a **Feature-Branch + Pull Request Workflow**:

1. Infrastructure changes are developed on isolated branches (`feat/staging-iac-definition`).

2. Pushing a branch triggers the GitHub Actions CD pipeline (`.github/workflows/cd-staging-iac.yml`), which executes:
   - `terraform fmt -check`
   - `terraform validate`
   - Full provisioning and recreation tests on an ephemeral runner.

3. Changes are merged into `main` only after automated pipeline and security checks pass.

---

## 4. How-To Guide: Provisioning & Reproducibility Testing

### Automated Provisioning

Run the wrapper script to initialize plugins, validate syntax, generate a deterministic plan, and provision the environment:

```bash
./provision.sh apply
```

### Environment Recreation ("Destroy and Recreate" Test)

To verify reproducibility and confirm zero manual configuration drift, run:

```bash
./provision.sh recreate
```

This command executes:

```bash
terraform destroy -var-file="staging.tfvars" -auto-approve
terraform apply -var-file="staging.tfvars" -auto-approve
```

This tears down all network and compute resources and reconstructs an identical staging environment, demonstrating that the infrastructure can be consistently recreated using Terraform.

git add README.md

git commit -m "docs: complete IaC staging documentation"

git push origin main