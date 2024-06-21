# Home lab

* Using Talos OS, pre provisions k8s.  

## flux

build apps manifest

```
flux build kustomization apps --path apps/local/ 
```

build infra  manifest

```
flux build kustomization infra-controllers-local --path infrastructure/local
```