
# Install NGINX Ingress Controller with Helm
```
$ helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --untar --version 0.17.1
$ cd nginx-ingress
$ kubectl apply -f crds
$ helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --version 0.17.1 
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
