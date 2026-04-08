# AGENTS.md — Coding Agent Instructions for trustgrid-infra-as-code

Practical reference for AI coding agents (Copilot, Cursor, Claude, etc.) working in this
repository. Read this before making any changes.

---

## Repository Layout

```
aws/terraform/modules/          # AWS Terraform reusable modules
azure/terraform/modules/        # Azure Terraform reusable modules
azure/terraform/examples/       # Azure end-to-end deployment examples
thousandeyes/terraform/modules/ # ThousandEyes Terraform modules
azure/az-cli/                   # Azure CLI helper scripts
azure/bicep/                    # Azure Bicep templates
.github/workflows/              # CI — only release.yml (tag-on-merge) exists
```

Modules live under `<cloud>/terraform/modules/`. Examples live under
`<cloud>/terraform/examples/`. There is **no monorepo build system, no package.json, no
Makefile, and no Go/Python test suite** in this repo. All quality checks are Terraform-native.

---

## Build / Lint / Test Commands

**There are no configured test framework commands in this repo.** No `make test`, no
`pytest`, no `go test`. All validation is Terraform CLI only.

### Standard per-directory workflow

Run inside each module or example directory you modify — no top-level script exists.

```bash
terraform init                # required before anything else
terraform fmt -recursive      # rewrites files in place; always commit the result
terraform validate            # static type/reference check; requires init
terraform plan                # verify against provider backend; needs real credentials
```

### Scoped single-directory validation

```bash
# Format check only (non-destructive, CI-style)
terraform fmt -check -recursive

# Validate a single module offline
cd aws/terraform/modules/trustgrid_single_node_auto_reg
terraform init -backend=false && terraform validate

# Validate an example (needs provider credentials for plan)
cd azure/terraform/examples/edge-cluster
terraform init && terraform validate
```

### Optional tools (not pre-installed — run only if available)

```bash
# tflint — https://github.com/terraform-linters/tflint
tflint --init && tflint

# tfsec — https://github.com/aquasecurity/tfsec  |  checkov — https://www.checkov.io/
tfsec .    # or: checkov -d .

# terraform-docs — https://terraform-docs.io/
terraform-docs markdown table --output-file README.md --output-mode inject .
```

### CI pipeline

`.github/workflows/release.yml` bumps a semver tag on merge to `main`. It does **not**
run Terraform validate or plan. There is no automated Terraform CI at this time.

### Cross-variable validation constraints require `terraform plan`

Terraform validation blocks that reference **more than one variable** (cross-variable
constraints) are **not evaluated by `terraform validate`** in Terraform < 1.6. They are
deferred to `terraform plan` time.

**Implication for testing:**

- `terraform validate` only catches *single-variable* constraints (enum checks, format
  checks, range checks that reference only `var.x`).
- `terraform plan` must be run to verify constraints of the form
  `!(var.a == "x" && var.b == null)`.

**Workflow for modules with cross-variable constraints:**

```bash
# Step 1 — catches single-variable errors offline
terraform init -backend=false && terraform validate

# Step 2 — catches cross-variable errors (plan will fail at auth for offline runs,
# but validation errors appear before provider calls and are visible in the output)
terraform plan -no-color
```

**When writing negative test fixtures:** document the expected tool in the fixture
header comment and ensure the test runner asserts on `terraform plan` exit code, not
`terraform validate`, for cross-variable constraint violations.

---

## Code Style Guidelines

### File organisation

Each module/example directory must contain `main.tf`, `variables.tf`, `outputs.tf`, and
`README.md`. Split large modules into logical files (`network.tf`, `compute.tf`) instead
of a single large `main.tf`.

### Providers and version constraints

- Declare all providers in a `terraform { required_providers {} }` block in `main.tf`.
- Use `~>` for Azure/ThousandEyes modules: `version = "~> 4.15.0"` (Azure)
- Use `>=` for GCP modules: `version = ">= 6.0"` (Google) — allows 6.x and 7.x+ without an artificial upper bound
- Use `>=` for AWS modules: `version = ">= 2.7.0"`
- Never place `provider` blocks inside reusable modules — only in examples.

### Naming conventions

- All identifiers use **`snake_case`** without exception.
- Prefix resource names with `var.name` or `var.name_prefix` so callers control
  namespacing: `"${var.name}-public-nic"`.
- Pin module `source` refs to a semver tag (`?ref=v0.2.0`), never a branch.

### Variables

- Every variable requires `type` and `description`. No exceptions.
- Use specific types (`string`, `number`, `bool`, `list(string)`, `object(...)`) — not
  bare `list` or `any`. Legacy bare `list` exists in older AWS modules; don't copy it.
- Mark SSH keys and license strings `sensitive = true`.
- Add `validation` blocks for any variable with a constrained set of valid values:
  ```hcl
  validation {
    condition     = contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be one of: 1, 2, or 3."
  }
  ```
- Use `default = null` for truly optional; `default = <value>` when a sensible default exists.

### Outputs

- Every output requires a `description`. Never leave it blank.
- Mark outputs that expose secrets `sensitive = true`.
- Group outputs by resource type with a `##` comment header.

### README / terraform-docs markers

Every module README must include the TF_DOCS marker pair — never hand-edit between them:
`<!-- BEGIN_TF_DOCS -->` … `<!-- END_TF_DOCS -->`

### Shell scripts and `.tpl` bootstrap files

Every shell script and `*.sh.tpl` template must open with `#!/bin/bash` followed by
`set -euo pipefail`. Template variables use Terraform's `templatefile()` syntax:
`${variable_name}`.

### Comments

- Use `##` as section headers in `.tf` files; `#` for inline notes.
- Explain *why*, not *what*. Never commit `TODO` or debug comments.

---

## Do / Don't

| Do | Don't |
|---|---|
| Run `terraform fmt -recursive` before committing | Manually align HCL — let `fmt` do it |
| Pin module `source` refs to a semver tag | Use `?ref=main` or a branch name |
| Add `validation` blocks to constrained variables | Accept any string where only a few values are valid |
| Add `description` to every variable and output | Leave `description` empty or omit it |
| Use `~>` for Azure providers, `>=` for GCP and AWS | Mix constraint styles randomly |
| Keep `provider` blocks out of reusable modules | Declare providers inside a module |
| Start every bootstrap script with `set -euo pipefail` | Write scripts that silently swallow errors |
| Regenerate `<!-- BEGIN_TF_DOCS -->` via `terraform-docs` | Hand-edit the generated table |
| Scope `terraform plan` to the directory being modified | Run plan against unrelated modules |

---

## Cursor / Copilot Rules

At the time of writing, **none of the following AI instruction files exist** in this repo:
`.cursor/rules`, `.cursorrules`, `.github/copilot-instructions.md`.

Use AGENTS.md as your primary instruction source until those files are created. If added
later, they take precedence over this document for tool-specific behaviour.

**Recommended rules to encode if you create those files:**

- Auto-apply `terraform fmt` on save for `.tf` files.
- Never suggest `any` or bare `list` as a variable type.
- Never suggest inline `provider` blocks inside modules.
- Suggest `validation` blocks for string variables with a fixed set of valid values.
- Enforce `#!/bin/bash\nset -euo pipefail` at the top of every shell/bootstrap file.

---

## Observed Conventions Summary

These patterns are consistent across the entire codebase — always follow them:

1. `terraform { required_providers {} }` block in every `main.tf`.
2. `snake_case` for all Terraform identifiers without exception.
3. `set -euo pipefail` in every shell and bootstrap script.
4. `lifecycle { ignore_changes = all }` on VM/instance resources — prevents Terraform
   from replacing running nodes due to post-boot drift.
5. `<!-- BEGIN_TF_DOCS --> / <!-- END_TF_DOCS -->` markers in all module READMEs.
6. `sensitive = true` on SSH keys and license variables.
7. `identity { type = "SystemAssigned" }` on Azure VMs — required for cluster HA
   role assignments.
8. `source_dest_check = false` on all AWS Trustgrid network interfaces — required
   for the node to route traffic between subnets.
9. Module sources reference this repo via GitHub HTTPS with a pinned tag:
   `github.com/trustgrid/trustgrid-infra-as-code//<path>?ref=vX.Y.Z`
