#!/bin/bash

set -e

FAILED=0

for file in talos/*; do
    if [ -f "$file" ]; then
        if ! grep -q 'sops:' "$file"; then
            echo "[ERROR] $file is not SOPS-encrypted. Run: sops --encrypt --in-place $file"
            FAILED=1
        fi
    fi
done

exit $FAILED
