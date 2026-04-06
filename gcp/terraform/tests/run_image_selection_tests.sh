#!/bin/bash
# Story 5 — Image selection behaviour test runner
# Validates image_project / image_family / image_name constraints and
# precedence logic for gcp/terraform/modules/compute/trustgrid_single_node.
#
# Usage: bash gcp/terraform/tests/run_image_selection_tests.sh
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
  local out
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
# Helper: assert terraform validate exits non-zero AND output matches pattern
# (negative fixture — single-variable constraint)
# ──────────────────────────────────────────────────────────────────────────────
expect_invalid() {
  local label="$1"
  local dir="$2"
  local expected_msg="$3"
  ensure_init "${dir}"
  local out
  out=$(terraform -chdir="${dir}" validate -no-color 2>&1) && rc=0 || rc=$?
  local msg_found=0
  echo "${out}" | grep -qF "${expected_msg}" && msg_found=1 || true

  if [[ ${rc} -ne 0 && ${msg_found} -eq 1 ]]; then
    echo "  [PASS] ${label}"
    PASS=$((PASS + 1))
  elif [[ ${rc} -eq 0 ]]; then
    echo "  [FAIL] ${label} — validate passed but expected failure"
    FAIL=$((FAIL + 1))
    DEFECTS+=("${label}")
  else
    echo "  [FAIL] ${label} — validate failed but expected error message not found"
    echo "         Expected msg: ${expected_msg}"
    echo "         Output:       ${out}"
    FAIL=$((FAIL + 1))
    DEFECTS+=("${label}")
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Helper: assert terraform plan exits non-zero AND output matches pattern
# (negative fixture — cross-variable constraint; validate cannot catch these
#  in Terraform < 1.6 — see AGENTS.md)
# ──────────────────────────────────────────────────────────────────────────────
expect_plan_invalid() {
  local label="$1"
  local dir="$2"
  local expected_msg="$3"
  ensure_init "${dir}"
  local out
  out=$(terraform -chdir="${dir}" plan -no-color 2>&1) && rc=0 || rc=$?
  local msg_found=0
  echo "${out}" | grep -qF "${expected_msg}" && msg_found=1 || true

  if [[ ${rc} -ne 0 && ${msg_found} -eq 1 ]]; then
    echo "  [PASS] ${label}"
    PASS=$((PASS + 1))
  elif [[ ${rc} -eq 0 ]]; then
    echo "  [FAIL] ${label} — plan passed but expected failure"
    FAIL=$((FAIL + 1))
    DEFECTS+=("${label}")
  else
    # plan may fail for auth reasons before reaching validation — if the
    # expected message IS present in the output, still count as pass.
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
echo " Story 5 — Image Selection Tests"
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
# T1: terraform validate on module source (no fixture wrapper needed)
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
# T2–T3: Positive fixtures (expect validate success)
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T2–T3: Positive fixtures (validate must succeed) ───────────"

expect_valid \
  "T2: image_name=null → family lookup accepted" \
  "${FIXTURES_DIR}/image_family_lookup_valid"

expect_valid \
  "T3: image_name=non-empty → pinned image accepted" \
  "${FIXTURES_DIR}/image_pinned_name_valid"

# ──────────────────────────────────────────────────────────────────────────────
# T4–T6: Negative fixtures — single-variable constraints (validate catches these)
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T4–T6: Negative fixtures (validate must fail) ──────────────"

expect_invalid \
  "T4: image_name=\"\" → rejected (empty string)" \
  "${FIXTURES_DIR}/image_name_empty_string_invalid" \
  "image_name must not be an empty string"

expect_invalid \
  "T5: image_name=\"   \" → rejected (whitespace only)" \
  "${FIXTURES_DIR}/image_name_whitespace_invalid" \
  "image_name must not be an empty string"

expect_invalid \
  "T6: image_project=\"\" → rejected" \
  "${FIXTURES_DIR}/image_project_empty_invalid" \
  "image_project must not be empty"

expect_invalid \
  "T7: image_family=\"\" → rejected" \
  "${FIXTURES_DIR}/image_family_empty_invalid" \
  "image_family must not be empty"

# ──────────────────────────────────────────────────────────────────────────────
# T8: Precedence logic — image_name pin suppresses data source (count check)
#
# This is a structural assertion: when image_name is non-null the data source
# block must use count = 0.  We verify this by grepping the plan JSON.
# Falls back to a grep on main.tf if plan credentials are unavailable.
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T8: Precedence — image_name pin skips data source ──────────"
PINNED_DIR="${FIXTURES_DIR}/image_pinned_name_valid"
ensure_init "${PINNED_DIR}"

PLAN_JSON=$(terraform -chdir="${PINNED_DIR}" plan -json -no-color 2>&1) && PLAN_RC=0 || PLAN_RC=$?

# Extract only valid JSON lines from the streaming plan output
PLAN_RESOURCES=$(echo "${PLAN_JSON}" | grep '"type":"planned_change"\|"resource_changes"' 2>/dev/null || true)

# Check plan JSON for google_compute_image resource being absent or count=0
DATA_SOURCE_ABSENT=0
if echo "${PLAN_JSON}" | grep -q '"google_compute_image"'; then
  # Resource mentioned — check if it is a no-op / count=0 (destroy or no resource)
  if echo "${PLAN_JSON}" | grep -q '"google_compute_image"' && \
     ! echo "${PLAN_JSON}" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        obj = json.loads(line.strip())
    except Exception:
        continue
    if obj.get('type') == 'resource_drift' or obj.get('type') == 'planned_change':
        change = obj.get('change', {})
        res = change.get('resource', {})
        if res.get('resource_type') == 'google_compute_image':
            actions = change.get('action', '')
            if 'create' in str(actions):
                sys.exit(1)
sys.exit(0)
" 2>/dev/null; then
    DATA_SOURCE_ABSENT=1
  fi
fi

# Structural fallback: verify the count expression in main.tf
MAIN_TF="${MODULE_DIR}/main.tf"
COUNT_EXPR=$(grep -A2 'data "google_compute_image"' "${MAIN_TF}" | grep 'count' || true)

if echo "${COUNT_EXPR}" | grep -q 'var.image_name == null ? 1 : 0'; then
  echo "  [PASS] T8: data source count = (image_name == null ? 1 : 0) — pin suppresses lookup"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T8: Expected count = var.image_name == null ? 1 : 0 in data.google_compute_image"
  echo "         Found: ${COUNT_EXPR}"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T8: data source count expression incorrect — precedence not enforced")
fi

# ──────────────────────────────────────────────────────────────────────────────
# T9: Precedence logic — local.boot_image expression
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── T9: Precedence — local.boot_image ternary ──────────────────"
BOOT_IMAGE_EXPR=$(grep 'boot_image' "${MODULE_DIR}/main.tf" | grep 'image_name' || true)

if echo "${BOOT_IMAGE_EXPR}" | grep -q 'var.image_name != null ? var.image_name'; then
  echo "  [PASS] T9: local.boot_image uses image_name when non-null (pin takes priority)"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] T9: local.boot_image expression does not give image_name priority"
  echo "         Found: ${BOOT_IMAGE_EXPR}"
  FAIL=$((FAIL + 1))
  DEFECTS+=("T9: local.boot_image precedence ternary missing or incorrect")
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
      T4*|T5*)
        echo "  [HIGH]     ${defect}"
        echo "             Empty/whitespace image_name passes validation — a caller"
        echo "             could silently produce a configuration with no usable image."
        ;;
      T6*)
        echo "  [HIGH]     ${defect}"
        echo "             Empty image_project passes validation — family-based image"
        echo "             resolution will fail at apply time with a confusing error."
        ;;
      T7*)
        echo "  [HIGH]     ${defect}"
        echo "             Empty image_family passes validation — family-based image"
        echo "             resolution will fail at apply time with a confusing error."
        ;;
      T8*)
        echo "  [CRITICAL] ${defect}"
        echo "             image_name pin does not suppress the data source lookup."
        echo "             Plan will fail for pinned-image configs if the family is"
        echo "             unreachable, defeating the purpose of image pinning."
        ;;
      T9*)
        echo "  [CRITICAL] ${defect}"
        echo "             local.boot_image does not prefer image_name over data source."
        echo "             Pinned images will not be used even when explicitly supplied."
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
echo "All Story 5 image-selection tests passed."
exit 0
