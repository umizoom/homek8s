# Install MetallB
```
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```

### Verify MetallB Installation
```
$ kubectl -n metallb-system get pods
$ kubectl api-resources| grep metallb
```

### Create IP Pool
```
$ kubectl -n metallb-system apply -f pool-1.yml
```

### Create L2Advertisement
```
$ kubectl -n metallb-system apply -f l2advertisement.yml
```

### Deploy Test Application
```
$ kubectl -n default apply -f web-app-deployment.yml
```

### Verify MetallB assigned an IP address
```
$ kubectl -n default get pods
$ kubectl -n default get services
```
