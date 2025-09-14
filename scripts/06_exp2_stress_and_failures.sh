#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"
RESULTS_DIR="$SCRIPT_DIR/../results"
NS=app
PROM_URL=${PROM_URL:-http://localhost:9090}
mkdir -p "$RESULTS_DIR"

SCHEDULER_POD=$(kubectl -n kube-system get pods -l component=kube-scheduler -o jsonpath='{.items[0].metadata.name}')
export SCHEDULER_POD

run_round(){
  local label=$1
  log "== Rodada: $label =="
  sed "s/\${SCHEDULER_POD}/${SCHEDULER_POD}/" "$MANIFESTS_DIR/chaos/pause_scheduler.yaml" | kubectl apply -f -
  kubectl apply -f "$MANIFESTS_DIR/chaos/stress_cpu_worker_a.yaml"
  kubectl apply -f "$MANIFESTS_DIR/chaos/drain_worker_b.yaml"
  log "Aguardando recuperação..."
  sleep 600
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=histogram_quantile(0.95,sum(rate(http_request_duration_seconds_bucket{job=\"fortio-server\"}[5m])) by (le))" | jq > "$RESULTS_DIR/exp2_${label}.json"
  kubectl delete -f "$MANIFESTS_DIR/chaos/stress_cpu_worker_a.yaml" --ignore-not-found
  kubectl delete -f "$MANIFESTS_DIR/chaos/drain_worker_b.yaml" --ignore-not-found
  kubectl delete podchaos pause-scheduler -n chaos-mesh --ignore-not-found
}

# Sem mitigação
kubectl -n "$NS" patch deployment fortio-server --type json -p='[{"op":"remove","path":"/spec/template/spec/priorityClassName"}]' || true
run_round sem_mitigacao

# PriorityClass
kubectl -n "$NS" patch deployment fortio-server --type merge -p '{"spec":{"template":{"spec":{"priorityClassName":"tier-1-critical"}}}}'
run_round prioridade

# PriorityClass + PDB
envsubst < "$MANIFESTS_DIR/pdb.yaml" | kubectl -n "$NS" apply -f -
run_round prioridade_pdb
