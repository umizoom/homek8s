
# Install NGINX Ingress Controller with Helm
```
helmfile apply
```

### Verify NGINX Ingress Installation
```
$ kubectl -n nginx-ingress get pods
$ kubectl -n nginx-ingress get services
```

### Create an Ingress for the Test Applications
```
$ kubectl -n default apply -f web-app-ingress.yml
$ kubectl -n default get ingress
```
