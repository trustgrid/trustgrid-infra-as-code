# PRD: Fix GCP Provider Constraint Blocking 7.x Consumers

## Introduction

New GCP Terraform modules currently pin the Google provider with `~> 6.0`, which enforces an upper bound `< 7.0.0`. Consumers already standardized on provider 7.x cannot initialize/resolve providers when using these modules.

## Root Cause

The `required_providers` blocks in all new GCP module `main.tf` files use `version = "~> 6.0"` (line 5 in each file), which is too restrictive for intended compatibility. The module contract intends to support 6.x and 7.x+, but `~> 6.0` mathematically excludes 7.x.

Defective declarations:
- `gcp/terraform/modules/compute/trustgrid_single_node/main.tf:5`
- `gcp/terraform/modules/network/trustgrid_mgmt_firewall/main.tf:5`
- `gcp/terraform/modules/network/trustgrid_gateway_firewall/main.tf:5`
- `gcp/terraform/modules/iam/trustgrid_node_service_account/main.tf:5`
- `gcp/terraform/modules/iam/trustgrid_cluster_route_role/main.tf:5`

Correct declaration in each module:
- `version = ">= 6.0"`

## Evidence

- **Logs:** Not provided.
- **Sentry:** Not applicable.
- **Code:** All five affected module `required_providers.google.version` entries are `~> 6.0`, creating upper-bound exclusion of 7.x.
- **Git history:** Not required to confirm this defect; the bug is directly observable in current module definitions.
- **Docs consistency drift:** Documentation still states GCP uses `~> 6.0`, including:
  - `AGENTS.md:116`
  - `gcp/terraform/modules/compute/trustgrid_single_node/README.md:512,518`
  - `gcp/terraform/modules/network/trustgrid_mgmt_firewall/README.md:116,122`
  - `gcp/terraform/modules/network/trustgrid_gateway_firewall/README.md:105,111`
  - `gcp/terraform/modules/iam/trustgrid_node_service_account/README.md:109,115`
  - `gcp/terraform/modules/iam/trustgrid_cluster_route_role/README.md:167,173`

## Goals

- Reproduce the provider-resolution failure in a test/fixture flow
- Fix the provider constraint root cause in all affected modules
- Prevent regression by aligning docs and verification steps

## User Stories

### US-001: Reproduce the defect in a test

**Description:** As a developer, I need a failing reproduction that shows current modules reject Google provider 7.x so I can verify the fix works.

**Acceptance Criteria:**

- [ ] Add/adjust a Terraform fixture or validation check that attempts to resolve with Google provider 7.x and fails before the fix due to module upper bound
- [ ] Test/check name clearly indicates provider-constraint incompatibility scenario
- [ ] Reproduction uses realistic module consumption path (module source + required providers)
- [ ] Typecheck passes

### US-002: Fix the root cause

**Description:** As a developer, I need to update affected GCP module provider constraints so modules support both 6.x and 7.x+ consumers.

**Acceptance Criteria:**

- [ ] In each affected module `main.tf`, change `required_providers.google.version` from `"~> 6.0"` to `">= 6.0"`
- [ ] No unrelated module behavior is changed
- [ ] The reproduction from US-001 passes after the change
- [ ] Typecheck passes

### US-003: Add regression and docs consistency coverage

**Description:** As a developer, I need documentation and regression coverage updated so the provider compatibility contract remains accurate.

**Acceptance Criteria:**

- [ ] Update documentation that currently claims GCP uses `~> 6.0` to reflect `>= 6.0`
- [ ] Regenerate/refresh module README TF docs sections if required by repository doc workflow
- [ ] Validate touched modules/examples with Terraform validation workflow
- [ ] Typecheck passes

## Functional Requirements

- FR-1: All affected GCP modules must declare `required_providers.google.version = ">= 6.0"`.
- FR-2: Module consumption with Google provider 7.x must no longer be blocked by module version constraints.
- FR-3: Repository docs must not claim a conflicting GCP provider constraint.

## Non-Goals

- Do NOT refactor unrelated Terraform resources or variables
- Do NOT change AWS/Azure/ThousandEyes provider policies
- Do NOT add new infrastructure features

## Technical Considerations

- **Files to modify (root cause):**
  - `gcp/terraform/modules/compute/trustgrid_single_node/main.tf`
  - `gcp/terraform/modules/network/trustgrid_mgmt_firewall/main.tf`
  - `gcp/terraform/modules/network/trustgrid_gateway_firewall/main.tf`
  - `gcp/terraform/modules/iam/trustgrid_node_service_account/main.tf`
  - `gcp/terraform/modules/iam/trustgrid_cluster_route_role/main.tf`
- **Docs consistency files to update where applicable:** module READMEs listed in Evidence + `AGENTS.md` (GCP provider guidance)
- **Validation commands:** run `terraform init -backend=false && terraform validate` in each touched module/example directory; verify provider resolution logic in reproduction fixture/check
- **Risk:** if provider 7 introduces breaking schema/API changes, this change only removes artificial version ceiling and does not guarantee all downstream configurations are semantically unchanged
