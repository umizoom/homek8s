# Home Lab

This repository contains Infrastructure as Code for Kubernetes home clusters, templated from the [Flux2 Kustomize Helm Example](https://github.com/fluxcd/flux2-kustomize-helm-example).


## Tools and Technologies

* Talos Linux
* Fluxcd
* Helm
* Kustomize
* [Task](https://taskfile.dev/usage)
* [Sops](https://github.com/getsops/sops)
* [Pre-Commit](https://pre-commit.com/index.html)

## Install Pre-Commit

```bash
pre-commit install
```

## Talos Linux

### Dashboard

```bash
task talos:dash
# OR
tadash1
```

### Scale Up Cluster

```bash
talosctl apply-config --insecure \
    --nodes [NODE IP] \
    --file controlplane.yaml | worker.yaml
```

### Upgrade Talos OS

1. Update talos version in `hacking/ansible/talos-upgrade.yaml`
2. Run `task talos:upgrade`
3. Manually update worker and control files with new version: `sops --d --in-place talos/worker.yaml`
4. Commit and push changes

### Generate Secrets

Generate `secrets.yaml` from control plane configuration:

```bash
talosctl gen secrets --from-controlplane-config controlplane-1.yaml
```

### Get Disk Information

```bash
talosctl get disks --nodes 192.168.2.2
```

## Kubernetes

Upgrade Kubernetes version:

Note: At times you need to run `brew install siderolabs/tap/talosctl` to upgrade talosctl CLI.

1. Test a dry run upgrade via: `talosctl --nodes 192.168.2.2 upgrade-k8s --to v1.35.1 --dry-run`
2. Run the actual upgrade: `talosctl --nodes 192.168.2.2 upgrade-k8s --to v1.35.1`
3. Update talos worker and control files via: `./hacking/k8-upgrade/update-sourcefiles.sh 1.35.1`
4. Commit and push changes

## Secrets

This project uses `SOPS` and the `external-secrets operator` with bit-warden as the secret store.

### SOPS

SOPS is used for encrypting files within the repo. This include the Talos config files.

For detailed information, see the [Flux SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/).


### External-Secrets Operator

The operator is used in conjunction with the [bitwarden-cli](https://github.com/umizoom/bitwarden-cli) container. All api keys, password etc use the operator.

The general idea is the Operator calls the bitwarden-cli via a GET to `http://bitwarden-cli.bitwarden.svc.cluster.local:8087/object/item/{{ .remoteRef.key }}`. The key is the ID of the secret in bit warden.

Only the pods in the namespace `external-secrets` can poll the `bitwarden-cli`. This is achieved via a `NetworkPolicy`.

The `bitwarden-cli` quries vault and returns the secret. The Operator then creates a K8s native `Secret` in the cluster based of the ExternalSecret spec.

For detailed information, see the [.](https://external-secrets.io/latest/examples/bitwarden/)



## Flux

Build apps manifest:

```bash
flux build kustomization apps --path apps/local/
```

Build infra local manifest:

```bash
flux build kustomization infra-controllers-local --path infrastructure/local
```

Build without connecting to cluster:

```bash
flux build kustomization infra-dependencies --path infrastructure/dependencies \
--kustomization-file infrastructure/dependencies/kustomization.yaml \
--dry-run
```

Sync git repo:

```bash
flux reconcile source git flux-system
```


### Bootstrap Staging and Production

Set up environment variables:

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=umizoom
export GITHUB_REPO=https://github.com/umizoom/homek8s
```

Bootstrap staging cluster:

```sh
flux bootstrap github \
    --context=kind-kind \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=refactor \
    --personal \
    --path=clusters/local
```

Bootstrap production cluster:

```sh
flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/production
```

## Diagram

![Home Network](./home_network_overview.png)
