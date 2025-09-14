#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_DIR="$SCRIPT_DIR/../helm-values"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"
PROFILE=${MINIKUBE_PROFILE:-slo-lab}

kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1
helm repo update >/dev/null 2>&1

log "Instalando kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n observability -f "$VALUES_DIR/kube-prometheus-stack.values.yaml" --wait

log "Aplicando dashboards do Grafana..."
kubectl -n observability create configmap slo-overview --from-file="$MANIFESTS_DIR/grafana/dashboards/slo_overview.json" -o yaml --dry-run=client | kubectl apply -f -
kubectl -n observability create configmap scheduler-latency --from-file="$MANIFESTS_DIR/grafana/dashboards/scheduler_latency.json" -o yaml --dry-run=client | kubectl apply -f -
for cm in slo-overview scheduler-latency; do
  kubectl -n observability annotate configmap "$cm" grafana_dashboard=1 --overwrite
done

log "URLs de acesso"
minikube -p "$PROFILE" service -n observability kube-prometheus-stack-grafana --url
minikube -p "$PROFILE" service -n observability kube-prometheus-stack-prometheus --url
