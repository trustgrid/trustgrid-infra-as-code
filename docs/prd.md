# PRD: Split GCP Gateway HA into Infra-Only and Full Automation Examples

## Introduction

Create two distinct GCP HA examples for Trustgrid so users can choose between:

1. **Infra-only deployment** for organizations without Trustgrid API access (Google provider only, manual registration default).
2. **Full automation deployment** for organizations with Trustgrid API access (Google + Trustgrid providers, full cluster/network configuration automation).

This removes ambiguity in the current `gcp/terraform/examples/gateway-cluster-ha` example, which is infrastructure-focused but currently tied to automatic registration inputs.

## Problem Statement

Current GCP HA example behavior and messaging do not clearly separate two real user journeys:

- users who can deploy infra but must register/configure in portal manually, and
- users who can fully automate Trustgrid cluster provisioning through provider resources.

Without a split, consumers either over-assume automation capability or lack a concrete reference for full end-to-end automation.

## Goals

- Provide a **clean infra-only HA example** with no Trustgrid provider dependency.
- Provide a **full HA automation example** that includes Trustgrid resources and ordering/online readiness gates.
- Keep all module references pinned to semver tags (never branch refs).
- Preserve Google provider constraints at `>= 6.0` where declared.

## Proposed Example Layout

- Keep and reshape existing path:
  - `gcp/terraform/examples/gateway-cluster-ha` → infra-only (manual default)
- Add second example directory:
  - `gcp/terraform/examples/gateway-cluster-ha-full`

## User Stories

### US-001: Infra-only HA example for non-API users

**Description:** As a platform team without Trustgrid API access, I want a GCP HA example that deploys all required infrastructure using only Google resources so I can register and configure cluster behavior manually.

**Acceptance Criteria:**

- [ ] `gateway-cluster-ha` requires only the `hashicorp/google` provider (`>= 6.0`)
- [ ] Example deploys two gateway nodes across distinct zones with static external IPs
- [ ] Example includes IAM route role and firewall coverage required for HA, including heartbeat TCP/9000
- [ ] Default registration mode is manual and does not require license/reg key variables
- [ ] README documents exact steps to switch to automatic registration when a license key becomes available
- [ ] All module `source` refs are pinned to semver tags (`?ref=vX.Y.Z`)

### US-002: Full HA automation example with Trustgrid provider

**Description:** As a team with Trustgrid API access, I want a full example that automates infrastructure and Trustgrid cluster/network configuration end-to-end.

**Acceptance Criteria:**

- [ ] New `gateway-cluster-ha-full` example declares both Google and Trustgrid providers
- [ ] Example provisions required Trustgrid resources: `tg_license` per node, `tg_cluster`, `tg_cluster_member`, `tg_node` online gate with timeout, `tg_node_cluster_config`, `tg_node_iface_names`, `tg_network_config`
- [ ] `tg_network_config` covers node LAN route glue and cluster cloud_route behavior
- [ ] GCP heartbeat firewall TCP/9000 is present and documented for HA cluster communications
- [ ] Resource graph includes dependency ordering sufficient to avoid race conditions between node readiness and Trustgrid config application
- [ ] All module refs remain semver pinned

### US-003: Documentation and migration clarity

**Description:** As a maintainer, I need clear docs so users can select the right example path and understand behavior differences.

**Acceptance Criteria:**

- [ ] `gateway-cluster-ha/README.md` explicitly labels the example as infra-only/manual-default
- [ ] README includes a migration section comparing infra-only vs full automation workflows
- [ ] New full example README includes prerequisites for Trustgrid API credentials and expected post-apply validation checks
- [ ] Any references to old single-path HA guidance are updated to point to both examples

## Functional Requirements

- FR-1: Infra-only HA example must be runnable with Google provider only.
- FR-2: Infra-only HA example must default to manual registration.
- FR-3: Full HA example must automate Trustgrid cluster and network configuration resources listed in US-002.
- FR-4: Both examples must include HA-critical firewall coverage including TCP/9000 heartbeat.
- FR-5: All example module sources must be pinned to semver release tags.

## Non-Goals

- Do not introduce new reusable modules unless implementation uncovers unavoidable gaps.
- Do not change non-GCP examples.
- Do not use branch-based module refs in merged example code or README snippets.

## Proposed File-Level Changes

### Update existing infra-focused HA example

- `gcp/terraform/examples/gateway-cluster-ha/main.tf`
  - convert default registration path to manual (remove required license/reg key in default flow)
  - add heartbeat firewall rule coverage for TCP/9000 if not already included
- `gcp/terraform/examples/gateway-cluster-ha/variables.tf`
  - make registration inputs optional or remove from infra-only default surface
  - retain zone A/B cross-variable validation
- `gcp/terraform/examples/gateway-cluster-ha/outputs.tf`
  - keep infra outputs focused on node IPs, SA emails, route role outputs
- `gcp/terraform/examples/gateway-cluster-ha/README.md`
  - rewrite as infra-only/manual-default guide
  - add section: “Enable auto registration when license key is available”

### Add full automation HA example

- `gcp/terraform/examples/gateway-cluster-ha-full/main.tf` (new)
- `gcp/terraform/examples/gateway-cluster-ha-full/variables.tf` (new)
- `gcp/terraform/examples/gateway-cluster-ha-full/outputs.tf` (new)
- `gcp/terraform/examples/gateway-cluster-ha-full/README.md` (new)

### Optional cross-reference updates

- `gcp/terraform/examples/*/README.md` references to HA example path(s) as needed.

## Risks and Migration Notes

- **Breaking expectation risk:** Existing users of `gateway-cluster-ha` may expect auto registration inputs; mitigate by documenting default-mode change and optional auto toggle path.
- **Provider/API sequencing risk:** Full automation adds eventual-consistency/race concerns between VM bootstrap, node online status, and Trustgrid config APIs; mitigate with explicit readiness gates and timeouts.
- **Permission scope risk:** Full example requires both GCP IAM and Trustgrid API credentials; README must include least-privilege guidance and failure symptoms.
- **Release hygiene risk:** Accidentally pinning module sources to feature branch refs; enforce semver refs only.
- **Route role dependency risk:** Ensure example continues to rely on fixed role permissions including `compute.networks.updatePolicy` already added in module.

## Validation Plan

- Run in each touched example directory:
  - `terraform init`
  - `terraform fmt -recursive`
  - `terraform validate`
  - `terraform plan` (with appropriate credentials)
- Verify docs and snippets contain only semver `?ref=vX.Y.Z` module refs.
