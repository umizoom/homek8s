# Home lab

* This contains IaC for my k8 home clusters
* It was templeted using https://github.com/fluxcd/flux2-kustomize-helm-example


## Tools and Technologies

* Talos Linux
* Fluxcd
* Helm
* Kustomize
* [Task](https://taskfile.dev/usage)
* [Sops](https://github.com/getsops/sops)

## Talos Linux

Dashboard

```
task talos:dash"
OR

tadash1 .. etc
```

Scale up cluster

```
talosctl apply-config --insecure \
    --nodes [NODE IP] \
    --file controlplane.yaml | worker.yaml
```
Upgrade talos OS

1. update talos version in `hacking/ansible/talos-upgrade.yaml`
2. Run `task talos:upgrade`
3. Manually update worker and control files via with new verison ` sops --d --in-place talos/worker.yaml`
4. Commit and push up changes

### K8s

Upgrade k8s

Note times you need to run `brew install siderolabs/tap/talosctl` to upgrade talosctl cli

1. Test a Dry run upgrade via: `talosctl --nodes 192.168.2.2 upgrade-k8s --to 1.33.4 --dry-run`
2. Run actual upgrade `talosctl --nodes 192.168.2.2 upgrade-k8s --to 1.33.4`
3. Update talos worker and control files via `./hacking/k8-upgrade/update-sourcefiles.sh 1.33.4`
4. Commit and push changes


### Flux

Build apps manifest

```
flux build kustomization apps --path apps/local/ 
```

Build infra local manifest

```
flux build kustomization infra-controllers-local --path infrastructure/local
```

Build without connecting to cluster

```
flux build kustomization infra-dependencies --path infrastructure/dependencies \
--kustomization-file infrastructure/dependencies/kustomization.yaml \
--dry-run
```

Sync git repo 

```
flux reconcile source git flux-system  
```


## Bootstrap staging and production

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=umizoom
export GITHUB_REPO=https://github.com/umizoom/homek8s
```

```sh
flux bootstrap github \
    --context=kind-kind \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=refactor \
    --personal \
    --path=clusters/local
```

```sh
flux bootstrap github \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/production
```

### Secrets 

https://fluxcd.io/flux/guides/mozilla-sops/


Encrypting secrets

```sh
task sops:encrypt
```

bootstrapping
```sh
flux create kustomization my-secrets \
--source=flux-system \
--path=./clusters/production \
--prune=true \
--interval=10m \
--decryption-provider=sops \
--decryption-secret=sops-gpg
```

## Diagram

![Home Network](./home_network_overview.png)