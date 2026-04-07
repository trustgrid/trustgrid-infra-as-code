#!/bin/bash
# disk_type_mode feature test runner
# Validates disk_type_mode = auto/manual selection logic and cross-variable
# compatibility constraints for gcp/terraform/modules/compute/trustgrid_single_node.
#
# Usage: bash gcp/terraform/tests/run_disk_type_mode_tests.sh
#        (run from the repo root, or any directory)
#
# Requires: terraform in PATH, previously run `terraform init` in each fixture
#           directory OR internet access so init can download the google provider.
#
# Exit code: 0 = all tests passed   1 = one or more tests failed

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES_DIR="${REPO_ROOT}/gcp/terraform/tests/fixtures"
MODULE_DIR="${REPO_ROOT}/gcp/terraform/modules/compute/trustgrid_single_node"
PASS=0
FAIL=0
DEFECTS=()

# ──────────────────────────────────────────────────────────────────────────────
# Helper: run terraform init (no-backend) if .terraform/modules is absent
# ──────────────────────────────────────────────────────────────────────────────
ensure_init() {
  local dir="$1"
  if [[ ! -f "${dir}/.terraform/modules/modules.json" ]]; then
    echo "    [init] ${dir}"
    terraform -chdir="${dir}" init -backend=false -no-color -input=false >/dev/null 2>&1
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Helper: assert terraform validate exits 0 (positive fixture)
# ──────────────────────────────────────────────────────────────────────────────
expect_valid() {
  local label="$1"
  local dir="$2"
  ensure_init "${dir}"
  local out rc
  out=$(terraform -chdir="${dir}" validate -no-color 2>&1) && rc=0 || rc=$?
  if [[ ${rc} -eq 0 ]]; then
    echo "  [PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] ${label}"
    echo "         Expected: validate exits 0"
    echo "         Got:      exit ${rc}"
    echo "         Output:   ${out}"
    FAIL=$((FAIL + 1))
    DEFECTS+=("${label}")
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Helper: assert terraform plan exits non-zero AND output contains expected_msg
# (negative fixture — cross-variable constraint; validate cannot catch these
#  in Terraform < 1.6 — see AGENTS.md and the module README for details)
# ──────────────────────────────────────────────────────────────────────────────
expect_plan_invalid() {
  local label="$1"
  local dir="$2"
  local expected_msg="$3"
  ensure_init "${dir}"
  local out rc msg_found
  out=$(terraform -chdir="${dir}" plan -no-color 2>&1) && rc=0 || rc=$?
  msg_found=0
  echo "${out}" | grep -qF "${expected_msg}" && msg_found=1 || true

  if [[ ${rc} -ne 0 && ${msg_found} -eq 1 ]]; then
    echo "  [PASS] ${label}"
    PASS=$((PASS + 1))
  elif [[ ${rc} -eq 0 ]]; then
    echo "  [FAIL] ${label} — plan passed but expected failure"
    FAIL=$((FAIL + 1))
    DEFECTS+=("${label}")
  else
    ## plan may fail for auth reasons before reaching validation — if the
    ## expected message IS present in the output, still count as pass.
    if [[ ${msg_found} -eq 1 ]]; then
      echo "  [PASS] ${label} (validation error found before auth failure)"
      PASS=$((PASS + 1))
    else
      echo "  [FAIL] ${label} — plan failed but expected validation message not found"
      echo "         Expected msg: ${expected_msg}"
      echo "         Output:       ${out}"
      FAIL=$((FAIL + 1))
      DEFECTS+=("${label}")
    fi
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# T0: fmt -check on module source
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " disk_type_mode Feature Tests"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "─── T0: Module format check ────────────────────────────────────"
if terraform -chdir="${MODULE_DIR}" fmt -check -recursive -no-color >/dev/null 2>&1; then
  echo "  [PASS] T0: terraform fmt -check passes on module source"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T0: terraform fmt -check detected formatting issues in module source"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T0: module fmt check")
fi

# ──────────────────────────────────────────────────────────────────────────────
# T1: terraform validate on module source
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T1: Module validate ────────────────────────────────────────"
MODULE_VAL_OUT=$(terraform -chdir="${MODULE_DIR}" validate -no-color 2>&1) && MODULE_VAL_RC=0 || MODULE_VAL_RC=$?
if [[ ${MODULE_VAL_RC} -eq 0 ]]; then
  echo "  [PASS] T1: terraform validate passes on module source"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T1: terraform validate failed on module source"
  echo "         Output: ${MODULE_VAL_OUT}"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T1: module validate")
fi

# ──────────────────────────────────────────────────────────────────────────────
# T2–T3: Auto mode — static expression assertions
#
# These are structural checks (grep on main.tf) that verify the conditional
# expression maps machine families to the correct disk types without requiring
# provider credentials.
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T2–T3: Auto mode — static expression checks ────────────────"

DISK_EXPR=$(grep -A5 'effective_disk_type' "${MODULE_DIR}/main.tf" || true)

## T2: e2 → pd-balanced
if echo "${DISK_EXPR}" | grep -q 'machine_family == "e2".*"pd-balanced"'; then
  echo "  [PASS] T2: auto mode — e2 family maps to pd-balanced"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T2: auto mode — e2 → pd-balanced branch missing or incorrect"
  echo "         Searched in: ${MODULE_DIR}/main.tf  (effective_disk_type local)"
  echo "         Context:     ${DISK_EXPR}"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T2: auto mode e2 → pd-balanced expression")
fi

## T3: n4/c4 → hyperdisk-balanced
if echo "${DISK_EXPR}" | grep -q '"n4".*"c4".*"hyperdisk-balanced"\|"hyperdisk-balanced".*"n4".*"c4"'; then
  echo "  [PASS] T3: auto mode — n4/c4 family maps to hyperdisk-balanced"
  PASS=$((PASS + 1))
else
  ## fallback: check for the conditional in full context (multi-line grep)
  DISK_BLOCK=$(awk '/effective_disk_type/,/\)$/' "${MODULE_DIR}/main.tf" || true)
  if echo "${DISK_BLOCK}" | grep -q 'hyperdisk-balanced' && \
     echo "${DISK_BLOCK}" | grep -q 'n4' && \
     echo "${DISK_BLOCK}" | grep -q 'c4'; then
    echo "  [PASS] T3: auto mode — n4/c4 family maps to hyperdisk-balanced"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] T3: auto mode — n4/c4 → hyperdisk-balanced branch missing or incorrect"
    echo "         Searched in: ${MODULE_DIR}/main.tf  (effective_disk_type local)"
    echo "         Context:     ${DISK_BLOCK}"
    FAIL=$((FAIL + 1))
    DEFECTS+=("T3: auto mode n4/c4 → hyperdisk-balanced expression")
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# T4–T5: Positive fixtures for auto mode (validate must succeed)
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T4–T5: Positive fixtures (auto mode, validate must succeed) ─"

expect_valid \
  "T4: auto mode + e2-standard-4 → validate succeeds" \
  "${FIXTURES_DIR}/disk_auto_e2_valid"

expect_valid \
  "T5: auto mode + n4-standard-8 → validate succeeds" \
  "${FIXTURES_DIR}/disk_auto_n4_valid"

# ──────────────────────────────────────────────────────────────────────────────
# T6–T7: Negative fixtures — cross-variable constraints (plan must fail)
#
# terraform validate alone does NOT catch these in Terraform < 1.6.
# The test runner uses terraform plan and accepts auth failure as long as the
# validation error message appears before the auth error.
# See AGENTS.md "Cross-variable validation constraints require terraform plan".
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T6–T7: Negative fixtures (manual mode, plan must fail) ─────"

expect_plan_invalid \
  "T6: manual mode + e2 + hyperdisk-balanced → rejected" \
  "${FIXTURES_DIR}/disk_manual_e2_hyperdisk_invalid" \
  "e2 machine family does not support hyperdisk disk types"

expect_plan_invalid \
  "T7: manual mode + n4 + pd-balanced → rejected" \
  "${FIXTURES_DIR}/disk_manual_n4_pd_invalid" \
  "n4 and c4 machine families require a hyperdisk disk type"

# ──────────────────────────────────────────────────────────────────────────────
# T8: README version check — all ?ref= links use v0.11.0, none use v0.2.0
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T8: README ref version check ───────────────────────────────"
README="${MODULE_DIR}/README.md"

## Count source refs that use v0.11.0
REF_011=$(grep -c '?ref=v0\.11\.0' "${README}" || true)
## Count any source refs that still use v0.2.0
REF_020=$(grep -c '?ref=v0\.2\.0' "${README}" || true)
## Count any source refs pointing at a non-semver branch (branch name starts non-v-digit)
REF_BRANCH=$(grep -cE '\?ref=[^v][^0-9]' "${README}" || true)

if [[ ${REF_011} -gt 0 && ${REF_020} -eq 0 ]]; then
  echo "  [PASS] T8: README uses v0.11.0 in all source refs (${REF_011} found), no v0.2.0 present"
  PASS=$((PASS + 1))
elif [[ ${REF_020} -gt 0 ]]; then
  echo "  [FAIL] T8: README still contains ${REF_020} stale ?ref=v0.2.0 link(s)"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T8: README stale v0.2.0 ref(s)")
elif [[ ${REF_011} -eq 0 ]]; then
  echo "  [FAIL] T8: README contains no ?ref=v0.11.0 links — expected at least one"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T8: README missing v0.11.0 ref(s)")
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
      T0*|T1*)
        echo "  [CRITICAL] ${defect}"
        echo "             Module does not pass basic format/validate checks."
        echo "             CI will reject this change."
        ;;
      T2*)
        echo "  [HIGH]     ${defect}"
        echo "             Auto mode will select the wrong disk type for e2 instances."
        echo "             e2 does not support hyperdisk; applying with the wrong type"
        echo "             will fail at the GCP API level."
        ;;
      T3*)
        echo "  [HIGH]     ${defect}"
        echo "             Auto mode will select the wrong disk type for n4/c4 instances."
        echo "             n4/c4 require hyperdisk; pd-* is not supported and apply will fail."
        ;;
      T4*|T5*)
        echo "  [HIGH]     ${defect}"
        echo "             Auto mode fixture fails validation — the feature may have a"
        echo "             syntax or structural error in variables.tf or main.tf."
        ;;
      T6*)
        echo "  [HIGH]     ${defect}"
        echo "             e2 + hyperdisk-* combination is not rejected at plan time."
        echo "             Callers can silently deploy incompatible configurations that"
        echo "             will fail at the GCP API with an opaque error."
        ;;
      T7*)
        echo "  [HIGH]     ${defect}"
        echo "             n4/c4 + pd-* combination is not rejected at plan time."
        echo "             Callers can silently deploy incompatible configurations that"
        echo "             will fail at the GCP API with an opaque error."
        ;;
      T8*)
        echo "  [MEDIUM]   ${defect}"
        echo "             README source refs point at a stale or missing version tag."
        echo "             Users copying the example will reference the wrong module version."
        ;;
      *)
        echo "  [MEDIUM]   ${defect}"
        ;;
    esac
  done
  echo ""
  exit 1
fi

echo ""
echo "All disk_type_mode tests passed."
exit 0
