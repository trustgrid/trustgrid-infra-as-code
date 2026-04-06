# Code Review: Story 1 — Single Module for Manual+Auto Registration

**Reviewed Module:** `gcp/terraform/modules/compute/trustgrid_single_node/`

**Review Date:** 2025-04-06

---

## Critical Issues

None identified. Module structure is sound and all Story 1 acceptance criteria are met at the validation level.

---

## Warnings

### 1. Missing Bootstrap/Startup Script Implementation (Story 1 Scope Gap)

**Severity:** Warning  
**Files:** `gcp/terraform/modules/compute/trustgrid_single_node/main.tf`, `variables.tf`  
**References:** PRD lines 43, 65; Story 1 acceptance criteria

**Finding:**

The module declares `registration_mode`, `license`, and `registration_key` variables with correct validation logic, but provides no mechanism to actually invoke these during instance bootstrap.

- **Current state:**
  - `license` is injected into instance metadata as `"tg-license"` when `registration_mode = "auto"` (main.tf lines 60–63)
  - No startup script, user data, or metadata_startup_script is configured
  - The `registration_key` variable is declared but never used anywhere in the module

- **Expected per PRD:**
  - Line 43: "Use startup/cloud-init style bootstrap template to support both registration flows"
  - Both registration modes need bootstrap logic to function end-to-end

- **Impact:**
  - The module validates correctly but a deployed instance would not actually register without external bootstrap logic
  - `registration_key` is declared but dead code unless it's incorporated into a bootstrap script
  - This may belong in a separate "bootstrap helper" module, or it may be in scope for Story 1

**Recommendation:**

Clarify scope with product team:
1. If bootstrap is in-scope for Story 1, add a `metadata_startup_script` parameter that can be populated by a separate bootstrap template module, or
2. If bootstrap is out-of-scope for Story 1, document this as a known limitation and create a follow-up story for bootstrap integration

---

### 2. registration_key Variable Declared but Not Used

**Severity:** Warning  
**Files:** `gcp/terraform/modules/compute/trustgrid_single_node/variables.tf` (lines 38–43)

**Finding:**

The `registration_key` variable is defined with correct `sensitive = true` attribute, but is never referenced in any metadata, cloud-init, or output. This variable is inert code.

- **Current usage:** 0 references in `main.tf` or `outputs.tf`
- **Expected per PRD line 22:** "Registration key can be passed as a sensitive variable" ✓ Met at input level, but not functionally integrated

**Impact:**

Users can pass a registration_key, but it has no effect on the deployed instance. This creates false expectations.

**Recommendation:**

Either:
1. Remove the variable until bootstrap logic is ready to consume it, or
2. Add it to metadata with a placeholder key (e.g., `"tg-registration-key"`) if bootstrap will be added soon, with a clear comment explaining the expected bootstrap flow

---

## Suggestions

### 1. Add Explanatory Comments for Registration Flow

**Files:** `gcp/terraform/modules/compute/trustgrid_single_node/main.tf` (lines 60–63)

**Finding:**

The conditional metadata injection is correct but could benefit from a comment explaining the bootstrap contract.

**Current code:**
```hcl
metadata = merge(
  var.extra_metadata,
  var.registration_mode == "auto" ? { "tg-license" = var.license } : {}
)
```

**Suggestion:**

Add an inline comment:
```hcl
metadata = merge(
  var.extra_metadata,
  # Note: tg-license is injected for auto-registration mode; a bootstrap script
  # must consume this metadata key and call the registration API with the license.
  var.registration_mode == "auto" ? { "tg-license" = var.license } : {}
)
```

**Impact:** Improves future maintainability and makes the contract with bootstrap logic explicit.

---

### 2. Document Registration Modes in README Usage Examples

**Files:** `gcp/terraform/modules/compute/trustgrid_single_node/README.md`

**Finding:**

Usage examples (lines 24–58) show manual and auto registration mode syntax, but do not explain:
- What happens after the instance boots in each mode
- How the license and registration_key are consumed
- What external registration flow is required (e.g., portal registration for manual, bootstrap-based for auto)

**Suggestion:**

Expand the "Manual registration" and "Auto registration" sections in README with a note about bootstrap requirements:

```markdown
### Manual registration (license omitted)

After first boot the node appears in the Trustgrid portal as "pending". Complete
registration there. **Note:** This module provides the instance; actual registration
logic and bootstrap must be supplied separately (see bootstrap helper module).

```

**Impact:** Sets clearer expectations for module consumers about scope boundaries.

---

### 3. Clarify GCP Provider Version Constraint Strategy

**Files:** `gcp/terraform/modules/compute/trustgrid_single_node/main.tf` (line 5)

**Finding:**

The module uses `version = "~> 6.0"` for the Google provider. AGENTS.md documents:
- AWS modules: `version = ">= 2.7.0"`
- Azure/ThousandEyes modules: `version = "~> 4.15.0"`
- GCP is not explicitly mentioned

**Current choice:** `~> 6.0` (allows 6.x.x, rejects 7.0+)

**Assessment:** This is reasonable for GCP (Google provider major version changes are typically breaking), but the AGENTS.md guidance should be updated to document GCP's constraint style for consistency.

**Suggestion:**

Update AGENTS.md to include:
```markdown
- Use `~>` for Azure/ThousandEyes/GCP modules: `version = "~> 6.0"`
- Use `>=` for AWS modules: `version = ">= 2.7.0"`
```

**Impact:** Low — this is a documentation enhancement, not a code issue.

---

## What's Done Well

✅ **Story 1 Acceptance Criteria Met (at Validation Level)**
- `registration_mode` enum with validation for "manual" | "auto" ✓
- `license` optional in manual mode, required in auto with proper validation ✓
- Registration key declared as sensitive ✓
- No placeholder/fake defaults ✓

✅ **AGENTS.md Conventions Fully Followed**
- `terraform { required_providers {} }` block present
- All identifiers use snake_case
- `lifecycle { ignore_changes = all }` on VM instance
- `sensitive = true` on license and registration_key variables
- TF_DOCS markers in README with auto-generated table
- Every variable has type and description
- Proper validation blocks with clear error messages

✅ **Module Design Boundaries Respected**
- No firewall resource definitions (delegated to caller)
- No service account creation (accepts email input)
- No VPC/subnet creation (accepts subnetwork references)
- Dual NIC architecture correctly implemented
- IP forwarding enabled for data-plane routing
- Correct network interface ordering (nic0 management, nic1 data)

✅ **Image Selection Logic Sound**
- Defaults to production Trustgrid image family/project
- Supports explicit image pinning via `image_name`
- Family fallback prevents unintended auto-upgrades via data source + locals pattern
- Self-link determinism maintained across plan/apply cycles

✅ **Registration Validation Logic Correct**
- Conditional license requirement validation prevents auto-registration without license
- Metadata injection using ternary prevents null injection
- No placeholders or fake defaults that could be accidentally committed

✅ **Shielded VM and Security Baseline**
- `enable_vtpm = true` and `enable_integrity_monitoring = true` hardcoded
- `enable_secure_boot = true` by default with documented override option
- Service account scoped to `["cloud-platform"]` (can be further restricted by IAM bindings)

✅ **Code Quality**
- Terraform format is correct
- `terraform validate` passes without errors
- Comments use `##` headers as per AGENTS.md
- Comments explain "why", not "what" (e.g., IP forwarding comment on line 32)

✅ **README Quality**
- Comprehensive usage examples for both manual and auto modes
- Explicit image pinning example provided
- Key design decisions clearly documented in table
- TF_DOCS marker pair present with generated reference documentation
- All inputs and outputs properly described

---

## Summary

**Overall Assessment:** ✅ **CLEAN to WARNING** (depending on bootstrap scope)

The module is production-ready for Story 1 **if bootstrap integration is explicitly out-of-scope**. All validation logic is correct, conventions are followed, and design boundaries are respected.

However, there is ambiguity about whether bootstrap script integration belongs in Story 1 (per PRD line 43). The `registration_key` variable is declared but unused, and there is no mechanism for the instance to consume the license metadata on first boot.

**Recommended Action:** 

Before merging, clarify with the product/engineering team whether:
1. Story 1 should include a `metadata_startup_script` input or support for cloud-init templates, or
2. Bootstrap is a follow-up story (Story 1.5 or new story) and the current module is acceptable as a "bootstrap-ready foundation"

If bootstrap is out-of-scope, update the README to explicitly document that "This module creates the instance; registration bootstrap logic is provided separately" and consider removing the unused `registration_key` variable to avoid false expectations.
