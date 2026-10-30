#!/usr/bin/env bash
# Bump the Talos installer image tag in the SOPS-encrypted machine configs.
# Run from the repo root (task talos:upgrade VERSION=v1.14.2 calls this).
# Uses `sops --set`, so nothing is decrypted to disk (see k8s-set-version.sh).

set -euo pipefail

# DRY_RUN=1 prints the planned changes and leaves every file untouched.
DRY_RUN=${DRY_RUN:-}

[[ $# -eq 1 ]] || { echo "Usage: $0 <version>   # Example: $0 v1.14.2" >&2; exit 1; }
VERSION=v${1#v}
[[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "[ERROR] '$1' is not a x.y.z version" >&2; exit 1; }

for file in talos/worker.yaml talos/control-*.yaml; do
    [[ -f $file ]] || continue
    current=$(yq -r '.machine.install.image // ""' "$file")
    [[ $current == factory.talos.dev/* || $current == ghcr.io/siderolabs/installer:* ]] || continue
    new="${current%:*}:$VERSION"
    [[ $current == "$new" ]] && continue
    [[ -n $DRY_RUN ]] || sops --set "[\"machine\"][\"install\"][\"image\"] \"$new\"" "$file"
    echo "$file: $current -> $new"
done
