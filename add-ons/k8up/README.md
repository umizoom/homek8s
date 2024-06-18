# https://github.com/k8up-io/k8up/tree/master/charts/k8up
helm repo add k8up-io https://k8up-io.github.io/k8up
kubectl apply -f https://github.com/k8up-io/k8up/releases/download/k8up-4.7.0/k8up-crd.yaml
helm install k8up k8up-io/k8up

