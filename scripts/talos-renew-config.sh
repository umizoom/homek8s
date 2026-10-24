#!/usr/bin/env bash
# Re-mint the Talos admin client cert from the cluster CA and update the
# SOPS-encrypted talos/talosconfig.yaml. Run from the repo root (task talos:renew).
#
# The CA key and the new admin key only ever exist in a private temp dir that is
# wiped on exit. The nodes are not touched: the CA is unchanged, so they already
# trust the new client cert.
#
# DRY_RUN=1 (task talos:renew_dry_run) runs every step except overwriting the repo files.

set -euo pipefail

CONTROL_PLANE_CONFIG=${CONTROL_PLANE_CONFIG:-talos/control-1.yaml}
TALOSCONFIG_FILE=${TALOSCONFIG_FILE:-talos/talosconfig.yaml}
CA_PEM=${CA_PEM:-.github/talos-ca.pem}
NODE=${NODE:-192.168.2.2}
HOURS=${HOURS:-8760}
DRY_RUN=${DRY_RUN:-}

umask 077
tmp=$(mktemp -d)
# Staged next to the real file so the .sops.yaml path rules apply to it.
staged="$(dirname "$TALOSCONFIG_FILE")/.talosconfig.new.yaml"
trap 'rm -rf "$tmp" "$staged"' EXIT

echo "Extracting Talos CA from $CONTROL_PLANE_CONFIG"
sops --decrypt "$CONTROL_PLANE_CONFIG" > "$tmp/control.yaml"
yq -r .machine.ca.crt "$tmp/control.yaml" | base64 -d > "$tmp/ca.crt"
yq -r .machine.ca.key "$tmp/control.yaml" | base64 -d > "$tmp/ca.key"
rm "$tmp/control.yaml"

echo "Generating admin client cert ($HOURS hours)"
(
    cd "$tmp"
    talosctl gen key --name admin
    talosctl gen csr --key admin.key --ip 127.0.0.1
    talosctl gen crt --ca ca --csr admin.csr --name admin --hours "$HOURS"
)

echo "Updating $TALOSCONFIG_FILE"
sops --decrypt --output-type yaml "$TALOSCONFIG_FILE" > "$tmp/talosconfig.yaml"
CA=$(base64 < "$tmp/ca.crt" | tr -d '\n') \
CRT=$(base64 < "$tmp/admin.crt" | tr -d '\n') \
KEY=$(base64 < "$tmp/admin.key" | tr -d '\n') \
    yq -i '.contexts[].ca = strenv(CA) | .contexts[].crt = strenv(CRT) | .contexts[].key = strenv(KEY)' "$tmp/talosconfig.yaml"

echo "Verifying the new config against $NODE"
talosctl --talosconfig "$tmp/talosconfig.yaml" --nodes "$NODE" version > /dev/null

# Encrypt a staged copy first so a failure never leaves plaintext at the real path.
cp "$tmp/talosconfig.yaml" "$staged"
sops --encrypt --in-place "$staged"
# Compare as JSON: sops re-serializes the YAML, so a byte comparison would always differ.
diff -q <(sops --decrypt --output-type yaml "$staged" | yq -o=json -P .) <(yq -o=json -P . "$tmp/talosconfig.yaml") > /dev/null \
    || { echo "[ERROR] encrypted config does not round-trip, repo left untouched" >&2; exit 1; }

if [[ -n $DRY_RUN ]]; then
    echo "DRY_RUN: new client cert would expire $(openssl x509 -noout -enddate -in "$tmp/admin.crt" | cut -d= -f2), $TALOSCONFIG_FILE left unchanged"
    exit 0
fi

mv "$staged" "$TALOSCONFIG_FILE"
# Public CA cert, committed so CI can watch the CA expiry without decrypting anything.
cp "$tmp/ca.crt" "$CA_PEM"

echo "New client cert expires: $(openssl x509 -noout -enddate -in "$tmp/admin.crt" | cut -d= -f2)"
echo "Commit with: git commit -am 'chore(talos): renew talosconfig client cert'"
