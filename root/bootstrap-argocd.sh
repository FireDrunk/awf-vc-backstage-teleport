#!/bin/bash

# Bootstrap ArgoCD
cd ../addons/argocd
helm dependency build

helm upgrade --install --create-namespace --values=values.yaml -n argocd argocd .

kubectl wait deployment -n argocd argocd-server --for condition=Available=True --timeout=90s
kubectl wait deployment -n argocd argocd-applicationset-controller --for condition=Available=True --timeout=90s
kubectl wait deployment -n argocd argocd-notifications-controller --for condition=Available=True --timeout=90s
kubectl wait deployment -n argocd argocd-redis --for condition=Available=True --timeout=90s
kubectl wait deployment -n argocd argocd-repo-server --for condition=Available=True --timeout=90s

kubectl apply -n argocd -f argocd-resources.yaml

cd -