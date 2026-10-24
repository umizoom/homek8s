# homek8s

This repo contains a **Talos Linux** Kubernetes cluster. Talos machine configs live in `talos/`, and secrets are SOPS-encrypted (see `.sops.yaml`).

## Interacting with the cluster

1. Decrypt the Talos config with `task talos:den`. This runs `sops --decrypt` on `talos/talosconfig.yaml` and writes the result to `/tmp/talosconfig.yaml` (defined in `.taskfiles/talos/Taskfile.yaml`).
2. After that you can run `kubectl` commands against the cluster.
3. Use `talosctl --talosconfig /tmp/talosconfig.yaml ...` to interact with the nodes.

There are 3 control-plane nodes, and they also act as the worker nodes.

## GitOps

We use **FluxCD** as the GitOps tool. Change cluster state by committing to git and letting Flux reconcile, rather than applying manifests by hand with `kubectl`.

- `clusters/{local,production}`: Flux entrypoints per cluster
- `infrastructure/`: infrastructure components and dependencies
- `apps/{base,local,production}`: applications

Dependency updates are handled by Renovate (`renovate.json`).
