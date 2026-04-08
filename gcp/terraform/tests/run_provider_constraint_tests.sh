#!/bin/bash
# Story 2 (US-002) — Provider constraint post-fix test runner
# Verifies that:
#   T1  A consumer pinned to Google provider >= 7.0 can successfully run
#       `terraform init` against the fixed module (which now declares >= 6.0).
#   T2  The trustgrid_single_node module explicitly declares `>= 6.0`
#       (not the former restrictive `~> 6.0`).
#
# Usage: bash gcp/terraform/tests/run_provider_constraint_tests.sh
#        (run from the repo root, or any directory)
#
# Requires: terraform in PATH, internet access so init can query the provider
#           registry (provider resolution happens before any local HCL evaluation).
#
# Exit code: 0 = all tests passed   1 = one or more tests failed
#
# Test matrix:
#   T1  Fixture init SUCCEEDS for >= 7.0 consumer against fixed (>= 6.0) module —
#       proves that the US-002 fix allows Google provider 7.x consumers.
#   T2  Module source (trustgrid_single_node) declares >= 6.0, NOT the old ~> 6.0 —
#       documents that the post-fix constraint is in place.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURE_DIR="${REPO_ROOT}/gcp/terraform/tests/fixtures/google_provider_7x_incompatibility"
MODULE_MAIN="${REPO_ROOT}/gcp/terraform/modules/compute/trustgrid_single_node/main.tf"
PASS=0
FAIL=0
DEFECTS=()

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Story 2 (US-002) — Provider Constraint Post-Fix Tests"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# T1: terraform init on the fixture MUST succeed
#
# The fixture consumer declares `version = ">= 7.0"`.  After the US-002 fix the
# module declares `version = ">= 6.0"` — no upper bound — so Terraform can
# resolve a provider version (e.g. 7.x) that satisfies both constraints.
#
# A successful init (exit code 0) proves the module allows Google provider 7.x.
# ──────────────────────────────────────────────────────────────────────────────
echo "─── T1: terraform init succeeds for >= 7.0 consumer + >= 6.0 module ────────"
echo "    Fixture: ${FIXTURE_DIR}"
echo "    (This may take a few seconds — provider registry query required)"
echo ""

## Clean any prior init state so the test is always fresh.
rm -rf "${FIXTURE_DIR}/.terraform" "${FIXTURE_DIR}/.terraform.lock.hcl" 2>/dev/null || true

INIT_OUT=$(terraform -chdir="${FIXTURE_DIR}" init -backend=false -no-color -input=false 2>&1) && INIT_RC=0 || INIT_RC=$?

if [[ ${INIT_RC} -eq 0 ]]; then
  echo "  [PASS] T1: terraform init succeeded — >= 7.0 consumer is compatible with >= 6.0 module"
  echo ""
  echo "         ── Evidence (resolved provider version) ────────────────────────────"
  echo "${INIT_OUT}" | grep -i \
    -e "Terraform has been successfully initialized" \
    -e "hashicorp/google" \
    -e "version" \
    | sed 's/^/         /' || true
  echo "         ─────────────────────────────────────────────────────────────────────"
  echo ""
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T1: terraform init FAILED — expected success for >= 6.0 module + >= 7.0 consumer"
  echo "         The module may have regressed to ~> 6.0, or there is a provider registry issue."
  echo ""
  echo "         Fixture consumer version: $(grep 'version' "${FIXTURE_DIR}/main.tf" | grep '>= 7' || echo '(not found)')"
  echo "         Module version:           $(grep 'version' "${MODULE_MAIN}" | head -1 || echo '(not found)')"
  echo ""
  echo "         Full terraform init output:"
  echo "${INIT_OUT}" | sed 's/^/         /' || true
  FAIL=$((FAIL + 1))
  DEFECTS+=("T1: init failed — module constraint may have regressed to ~> 6.0")
fi

# ──────────────────────────────────────────────────────────────────────────────
# T2: Module source declares >= 6.0 (post-fix state)
#
# This assertion confirms that the US-002 fix is in place: the module must use
# the open-ended `>= 6.0` constraint rather than the old tilde-range `~> 6.0`.
# ──────────────────────────────────────────────────────────────────────────────
echo "─── T2: Module constraint is >= 6.0 (post-fix state verified) ──────────────"

## Extract the google provider version line from the module's main.tf.
## Strip spaces and quotes for reliable comparison.
MODULE_CONSTRAINT=$(grep -A2 'source.*=.*"hashicorp/google"' "${MODULE_MAIN}" | grep 'version' | tr -d ' "' || true)

CONSTRAINT_OK=0
if echo "${MODULE_CONSTRAINT}" | grep -q '>=6.0'; then
  CONSTRAINT_OK=1
fi

if [[ ${CONSTRAINT_OK} -eq 1 ]]; then
  echo "  [PASS] T2: module constraint is '>= 6.0' — post-fix state confirmed"
  echo "         (${MODULE_MAIN})"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T2: module constraint is NOT '>= 6.0'"
  echo "         Found: ${MODULE_CONSTRAINT}"
  echo "         Expected: version = \">= 6.0\" (US-002 fix must be in place)"
  echo ""
  ## Also flag if the old tilde-range constraint crept back in.
  if echo "${MODULE_CONSTRAINT}" | grep -q '~>6.0'; then
    echo "         REGRESSION DETECTED: module has reverted to '~> 6.0'"
  fi
  FAIL=$((FAIL + 1))
  DEFECTS+=("T2: module constraint is not '>= 6.0' — US-002 fix may be missing or reverted")
fi

# ──────────────────────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"

if [[ ${FAIL} -gt 0 ]]; then
  echo ""
  echo "DEFECT REPORT"
  echo "─────────────"
  for defect in "${DEFECTS[@]}"; do
    case "${defect}" in
      T1*)
        echo "  [CRITICAL] ${defect}"
        echo "             Verify that the module declares >= 6.0 (not ~> 6.0)."
        echo "             The US-002 fix must be applied before provider 7.x consumers can use this module."
        ;;
      T2*)
        echo "  [CRITICAL] ${defect}"
        echo "             The module constraint must be '>= 6.0' to allow Google provider 7.x."
        echo "             Check gcp/terraform/modules/compute/trustgrid_single_node/main.tf."
        ;;
      *)
        echo "  [HIGH]     ${defect}"
        ;;
    esac
  done
  echo ""
  exit 1
fi

echo ""
echo "All Story 2 provider-constraint tests passed."
exit 0
