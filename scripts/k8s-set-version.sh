#!/usr/bin/env bash
# Bump the Kubernetes component image tags in the SOPS-encrypted Talos machine
# configs. Run from the repo root (task talos:k8s_version VERSION=1.37.2).
#
# Image fields are not in .sops.yaml's encrypted_regex, so they are readable in
# the encrypted files. Each one is edited with `sops --set`, which updates the
# value and the MAC in place: nothing is decrypted to disk and there is no
# decrypt/edit/re-encrypt window.

set -euo pipefail

# DRY_RUN=1 prints the planned changes and leaves every file untouched.
DRY_RUN=${DRY_RUN:-}

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>   # Example: $0 1.37.2" >&2
    exit 1
fi
VERSION=${1#v}
[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "[ERROR] '$1' is not a x.y.z version" >&2; exit 1; }

FILES=(talos/worker.yaml talos/control-*.yaml)
# yq path : image repository
COMPONENTS=(
    ".machine.kubelet.image|ghcr.io/siderolabs/kubelet"
    ".cluster.apiServer.image|registry.k8s.io/kube-apiserver"
    ".cluster.controllerManager.image|registry.k8s.io/kube-controller-manager"
    ".cluster.proxy.image|registry.k8s.io/kube-proxy"
    ".cluster.scheduler.image|registry.k8s.io/kube-scheduler"
)

for file in "${FILES[@]}"; do
    [[ -f $file ]] || continue
    for entry in "${COMPONENTS[@]}"; do
        path=${entry%%|*}
        repo=${entry#*|}
        current=$(yq -r "$path // \"\"" "$file")
        [[ $current == "$repo":* ]] || continue
        new="$repo:v$VERSION"
        [[ $current == "$new" ]] && continue
        # yq path (.a.b) -> sops path (["a"]["b"])
        sops_path=$(sed -E 's/\./"]["/g; s/^"\]/[/; s/$/"]/' <<< "$path")
        [[ -n $DRY_RUN ]] || sops --set "$sops_path \"$new\"" "$file"
        echo "$file: $current -> $new"
    done
done

echo "Kubernetes images set to v$VERSION. Review with 'git diff --stat', then commit."
