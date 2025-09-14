#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
PROM_URL=${PROM_URL:-http://localhost:9090}
NS=app
DEPLOY=fortio-server
mkdir -p "$RESULTS_DIR"

log "Baseline 5min"
sleep 300
curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=histogram_quantile(0.95,sum(rate(http_request_duration_seconds_bucket{job=\"fortio-server\"}[5m])) by (le))" | jq > "$RESULTS_DIR/exp1_baseline.json"

log "Injetando falha de etiquetamento"
kubectl -n "$NS" patch deployment "$DEPLOY" --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"force":"node-x"}}}}}'

log "Observando por 25min"
sleep 1500
curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=sum(kube_pod_status_phase{phase=\"Pending\",namespace=\"$NS\"})" | jq > "$RESULTS_DIR/exp1_during.json"

log "Mitigando"
kubectl -n "$NS" patch deployment "$DEPLOY" --type json -p='[{"op":"remove","path":"/spec/template/spec/nodeSelector"}]'
kubectl -n "$NS" rollout status deployment "$DEPLOY" --timeout=300s
sleep 300
curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=sum(kube_pod_status_phase{phase=\"Pending\",namespace=\"$NS\"})" | jq > "$RESULTS_DIR/exp1_post.json"

log "Resumo"
jq -s '{baseline:.[0], during:.[1], post:.[2]}' "$RESULTS_DIR/exp1_baseline.json" "$RESULTS_DIR/exp1_during.json" "$RESULTS_DIR/exp1_post.json" > "$RESULTS_DIR/exp1_summary.json"
cat "$RESULTS_DIR/exp1_summary.json"
