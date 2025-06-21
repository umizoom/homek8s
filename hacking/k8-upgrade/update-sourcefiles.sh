#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <new-version>   # Example: $0 1.34.0"
  exit 1
fi

NEW_VERSION="$1"

# 1. Run the talos:den task
task talos:den

# 2. Decrypt all talos/worker and talos/control node files
for file in talos/worker.yaml talos/control-*.yaml; do
  if [ -f "$file" ]; then
    sops --decrypt --in-place "$file"
  fi
done

# 3. Update only the version in the image tags
for file in talos/worker.yaml talos/control-*.yaml; do
  if [ -f "$file" ]; then
    # kubelet
    sed -i '' -E "s|(ghcr\.io/siderolabs/kubelet:v)[0-9]+\.[0-9]+\.[0-9]+|\1${NEW_VERSION}|g" "$file"
    # apiserver
    sed -i '' -E "s|(registry\.k8s\.io/kube-apiserver:v)[0-9]+\.[0-9]+\.[0-9]+|\1${NEW_VERSION}|g" "$file"
    # controller-manager
    sed -i '' -E "s|(registry\.k8s\.io/kube-controller-manager:v)[0-9]+\.[0-9]+\.[0-9]+|\1${NEW_VERSION}|g" "$file"
    # proxy
    sed -i '' -E "s|(registry\.k8s\.io/kube-proxy:v)[0-9]+\.[0-9]+\.[0-9]+|\1${NEW_VERSION}|g" "$file"
    # scheduler
    sed -i '' -E "s|(registry\.k8s\.io/kube-scheduler:v)[0-9]+\.[0-9]+\.[0-9]+|\1${NEW_VERSION}|g" "$file"
  fi
done

# 4. Re-encrypt all files
for file in talos/worker.yaml talos/control-*.yaml; do
  if [ -f "$file" ]; then
    sops --encrypt --in-place "$file"
  fi
done

echo "Talos image versions updated to v$NEW_VERSION and files re-encrypted."