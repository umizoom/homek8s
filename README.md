# Home lab

* This contains IaC for my k8 home clusters
* It was templeted using https://github.com/fluxcd/flux2-kustomize-helm-example


## Tools and Technologies

* Talos Linux
* Fluxcd
* Helm
* Kustomize

## Talos Linux

Dashboard

```
talosctl dashboard -n 192.168.2.2 -e 192.168.2.2"
```

Scale up cluster

```
talosctl apply-config --insecure \
    --nodes [NODE IP] \
    --file controlplane.yaml | worker.yaml
```

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
    --context=homecluster \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=refactor \
    --personal \
    --path=clusters/production
```