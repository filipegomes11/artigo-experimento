#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/../tools"
RESULTS_DIR="$SCRIPT_DIR/../results"
PROM_URL=${PROM_URL:-http://localhost:9090}
mkdir -p "$RESULTS_DIR"

log "Exportando consultas PromQL"
"$TOOLS_DIR/export_promql.sh" > "$RESULTS_DIR/promql_used.txt"

log "Coletando métricas"
> "$RESULTS_DIR/metrics.csv"
while IFS=':' read -r name query; do
  value=$(curl -sG "$PROM_URL/api/v1/query" --data-urlencode "query=$query" | jq -r '.data.result[0].value[1]')
  echo "$name,$value" >> "$RESULTS_DIR/metrics.csv"
done < "$RESULTS_DIR/promql_used.txt"

{
  echo "|metric|value|"
  echo "|---|---|"
  while IFS=',' read -r m v; do
    echo "|$m|$v|"
  done < "$RESULTS_DIR/metrics.csv"
} > "$RESULTS_DIR/summary.md"

log "Resumo salvo em $RESULTS_DIR/summary.md"
