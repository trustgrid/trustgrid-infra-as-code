#!/bin/bash

set -euo pipefail

# Trustgrid node bootstrap script — executed by GCP metadata_startup_script on first boot.
#
# In 'auto' mode this script writes the license (and optional registration key) to
# the expected on-disk paths and then invokes the Trustgrid registration binary.
# In 'manual' mode it exits immediately; the operator will complete registration
# through the Trustgrid portal after first boot.
#
# Template variables (injected by Terraform templatefile()):
#   registration_mode — "auto" or "manual"
#   license           — Trustgrid node license (empty string when mode is manual)
#   registration_key  — optional cluster/configuration key (empty string when not set)

REGISTRATION_MODE="${registration_mode}"
TG_DIR="/usr/local/trustgrid"
LOG_FILE="/var/log/tg-bootstrap.log"

exec > >(tee -a "$${LOG_FILE}") 2>&1

echo "[tg-bootstrap] Starting — mode=$${REGISTRATION_MODE}"

if [ "$${REGISTRATION_MODE}" = "manual" ]; then
  # Nothing to do — the node will surface as "pending" in the Trustgrid portal.
  # Complete registration there.
  echo "[tg-bootstrap] Manual registration mode — skipping automated registration."
  echo "[tg-bootstrap] Log into the Trustgrid portal to complete node registration."
  exit 0
fi

## Auto registration path ────────────────────────────────────────────────────

echo "[tg-bootstrap] Auto registration mode — writing credentials."

# Write the license to the path the Trustgrid agent expects.
LICENSE_FILE="$${TG_DIR}/license.txt"
mkdir -p "$${TG_DIR}"
echo "${license}" > "$${LICENSE_FILE}"
chmod 600 "$${LICENSE_FILE}"

# Write the registration key when one was supplied.
REGISTRATION_KEY="${registration_key}"
if [ -n "$${REGISTRATION_KEY}" ]; then
  REG_KEY_FILE="$${TG_DIR}/registration-key.txt"
  echo "$${REGISTRATION_KEY}" > "$${REG_KEY_FILE}"
  chmod 600 "$${REG_KEY_FILE}"
  echo "[tg-bootstrap] Registration key written."
fi

echo "[tg-bootstrap] Invoking Trustgrid registration."

# Retry until the registration binary succeeds — the instance may need a moment
# to reach the control plane after network interfaces come up.
cd "$${TG_DIR}"
while ! bin/register.sh; do
  echo "[tg-bootstrap] Registration failed — retrying in 60 seconds..."
  sleep 60
done

echo "[tg-bootstrap] Registration complete."
