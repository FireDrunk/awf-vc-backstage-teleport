#!/bin/bash

set -e
k3d cluster create --config cluster.yaml

# Helm Repo's
helm repo add cilium https://helm.cilium.io/
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo add kyverno https://kyverno.github.io/kyverno
helm repo add policy-reporter https://kyverno.github.io/policy-reporter
helm repo add external-secrets https://charts.external-secrets.io
helm repo add stakater https://stakater.github.io/stakater-charts

helm repo update

# Install Cilium
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --set operator.replicas=1 \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=${API_SERVER_IP} \
  --set k8sServicePort=6443 \
  --set clusterPoolIPv4PodCIDRList="10.249.0.0/16" \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.hostNetwork.enabled=true \
  --set ipv6.enabled=false

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key \
  -out /tmp/tls.crt \
  -subj "/CN=*.localhost" \
  -addext "subjectAltName=DNS:*.localhost,DNS:localhost" \
  2>/dev/null

kubectl create secret tls cilium-gateway-tls \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  -n kube-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ TLS certificate created"

echo "⏳ Waiting for Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

echo "⏳ Waiting for Cilium DaemonSet..."
kubectl -n kube-system rollout status ds/cilium --timeout=120s

echo "⏳ Waiting for Cilium CRDs..."
until kubectl get crd ciliumclusterwidenetworkpolicies.cilium.io &>/dev/null; do
  echo "  CRD not yet available, waiting 7s..."
  sleep 7
done
echo "✅ CRDs available"

kubectl apply -f cilium-resources.yaml
echo "✅ Cilium addons applied"

