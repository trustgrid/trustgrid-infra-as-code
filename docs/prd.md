# PRD: GCP Terraform Modules for Trustgrid Nodes (Issue #31)

## Project
- **Name:** trustgrid-infra-as-code — GCP Terraform Module Suite (v1)
- **Ticket:** https://github.com/trustgrid/trustgrid-infra-as-code/issues/31
- **Goal:** Add first-class GCP Terraform support for Trustgrid node deployments, with a single-node module that supports both manual and auto registration, plus helper modules and examples for common production patterns.

## Scope and Boundaries
- **In scope:** New `gcp/` Terraform modules and examples only.
- **Out of scope:** Any AWS/Azure functional changes.
- **Ownership model:** Main node module consumes existing network resources (VPC/subnets/etc.) and does **not** own core network creation.

## Key Requirements (Confirmed)
1. Single node module supports both manual and auto registration.
2. `license` input is optional in manual mode, required in auto mode with validation (no placeholder/fake defaults).
3. Public exposure modes:
   - `direct_static_ip` (default)
   - `byo_public_ip`
   - `private_only`
4. Gateway ingress in v1: direct public IP only (no LB requirement).
5. Redeploy stability objective: preserve public IP.
6. Registration key can be passed as a sensitive variable.
7. Service account creation is outside main node module (helper module provided).
8. IAM helper for HA route-management permissions is required.
9. Main node module does not manage firewall rules; helper module(s) provided for least-privilege management/gateway rule creation.
10. Image defaults target production Trustgrid image family/project; support overrides for test image variants and explicit pinning.
11. Required examples:
   - single-node manual
   - single-node auto
   - dual-node HA using IAM helper
12. Include deployment best practices: dual NIC model, `can_ip_forward`, mgmt/data separation, and relevant port expectations.

## Technical Design

### 1) Main Module: `trustgrid_single_node`
**Path:** `gcp/terraform/modules/compute/trustgrid_single_node`

Core behaviors:
- Create a GCE VM with two NICs:
  - `nic0`: management/public-side subnet
  - `nic1`: data/private subnet
- Set `can_ip_forward = true` on instance.
- Use startup/cloud-init style bootstrap template to support both registration flows.
- Registration mode switch:
  - `registration_mode = "manual" | "auto"`
  - Validation enforces:
    - manual: `license` may be null/empty
    - auto: `license` must be non-empty and basic format sanity checks
- Public exposure switch:
  - `public_exposure_mode = "direct_static_ip" | "byo_public_ip" | "private_only"`
  - `direct_static_ip`: module reserves static external IP and attaches to mgmt NIC
  - `byo_public_ip`: module consumes provided static address resource/self_link
  - `private_only`: no external address
- No firewall resources in this module.
- No service account creation in this module; it accepts service account email.
- Image selection:
  - Defaults to Trustgrid production project/family
  - Optional `image_project`, `image_family`, and `source_image` override for explicit pinning/test variants
- Lifecycle strategy aimed at IP stability and node drift tolerance where appropriate.

Planned main inputs (high level):
- identity/placement: `project_id`, `region`, `zone`, `name`
- networking: `management_subnetwork`, `data_subnetwork`, optional static internal IP inputs
- exposure: `public_exposure_mode`, optional `byo_public_ip_address`
- trustgrid registration: `registration_mode`, `license` (sensitive), `registration_key` (sensitive), `enroll_endpoint`
- compute/image: machine type, disk config, image defaults/overrides
- IAM binding inputs only by reference (`service_account_email`)

Planned outputs (high level):
- instance identifiers/self_link
- management/data NIC identifiers and internal IPs
- effective external IP (if any)
- service account email in use

### 2) Helper Module: Service Account
**Path:** `gcp/terraform/modules/iam/trustgrid_node_service_account`

Responsibilities:
- Create service account only.
- Optionally output generated key is **not** in scope (avoid secret sprawl).
- Output service account email and principal identifiers.

### 3) Helper Module: HA Route Management IAM
**Path:** `gcp/terraform/modules/iam/trustgrid_cluster_route_role`

Responsibilities:
- Create custom IAM role with least-privilege route update permissions required for HA failover behavior.
- Bind role to provided service account member(s) at project scope.

### 4) Helper Module(s): Firewall Rules
**Path:** `gcp/terraform/modules/network/`

Planned modules:
- `trustgrid_gateway_firewall_rules`
  - Inbound for gateway ports (TCP/UDP 8443), optional WireGuard UDP 51820, optional app gateway TCP 443.
- `trustgrid_outbound_control_plane_firewall_rules`
  - Egress helper for Trustgrid control plane access expectations.

Design constraints:
- Firewall logic remains outside main node module.
- Modules support target tags/service accounts for least privilege.

### 5) Examples
**Path:** `gcp/terraform/examples/`

1. `single-node-manual`
   - Existing network references
   - No license required
   - Default exposure (`direct_static_ip`)

2. `single-node-auto`
   - Existing network references
   - License required + validated
   - Optional registration key variable

3. `gateway-cluster-ha`
   - Two nodes using main module
   - Route IAM helper applied
   - Firewall helper usage demonstrated
   - Auto registration acceptable for v1 example

## User Stories

### Story 1 — Single module for manual+auto registration
As a platform engineer, I want one GCP node module supporting manual and automatic registration so I can standardize deployments and reduce module sprawl.

**Acceptance Criteria**
1. Module exposes `registration_mode` with values `manual` and `auto`.
2. `license` is optional in manual mode.
3. `license` is required/validated in auto mode (no fake default).
4. Registration key can be passed as a sensitive variable.

### Story 2 — Public exposure modes and stable redeploy
As an operator, I want clear public exposure options so I can match security and routing requirements while preserving public IP across redeploys.

**Acceptance Criteria**
1. Module supports `direct_static_ip`, `byo_public_ip`, and `private_only` modes.
2. Default mode is `direct_static_ip`.
3. Public IP is preserved for redeploy scenarios in default mode.
4. v1 does not require or create a load balancer for gateway ingress.

### Story 3 — Externalized network ownership and firewall management
As a network owner, I want to keep VPC/subnet/firewall ownership separate from node provisioning.

**Acceptance Criteria**
1. Main node module consumes existing subnet identifiers and does not create VPC/subnets.
2. Main node module does not create firewall rules.
3. Firewall helper modules provide least-privilege rule creation patterns for mgmt/gateway.

### Story 4 — IAM helper modules for service account + HA route permissions
As a security engineer, I need explicit helper modules to control identity and HA route permissions.

**Acceptance Criteria**
1. Service account helper module creates service account and outputs email.
2. Route IAM helper module defines least-privilege route-management role and bindings.
3. Main node module accepts service account email input and does not create service accounts.

### Story 5 — Production image defaults with controlled overrides
As a release engineer, I need safe defaults and override controls for image provenance and reproducibility.

**Acceptance Criteria**
1. Defaults target production Trustgrid image family/project.
2. Inputs allow test variant overrides (project/family).
3. Inputs allow explicit image version pinning via source image override.

### Story 6 — Ready-to-run examples
As a customer engineer, I want examples for common deployment topologies so I can deploy quickly with minimal translation.

**Acceptance Criteria**
1. Example exists for single-node manual registration.
2. Example exists for single-node auto registration.
3. Example exists for dual-node HA with IAM route helper.

## Test Plan (for Ticket)
1. `terraform fmt -recursive` across new `gcp/` tree.
2. `terraform init -backend=false && terraform validate` in each new module directory.
3. `terraform init -backend=false && terraform validate` in each example directory.
4. Validation-focused negative tests:
   - auto mode without license fails validation.
   - invalid `public_exposure_mode` fails validation.
5. Static review checks:
   - main module contains no firewall resources.
   - main module contains no service account resource creation.
   - VM has dual NIC and `can_ip_forward = true`.
   - helper modules encapsulate IAM/firewall concerns.

## Risks / Assumptions
- Final least-privilege IAM action set for HA route management may need refinement after live failover testing.
- Exact Trustgrid control-plane egress destination set may evolve; firewall helper should allow controlled extension.
- Trustgrid production image project/family identifiers are assumed known and available in target org/permissions.
- BYO public IP attachment behavior depends on operator supplying a valid regional address resource compatible with selected zone/instance settings.

## Proposed Branch Name
`feature/31-gcp-terraform-modules`
