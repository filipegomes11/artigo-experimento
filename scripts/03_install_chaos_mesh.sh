#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_DIR="$SCRIPT_DIR/../helm-values"

kubectl create namespace chaos-mesh --dry-run=client -o yaml | kubectl apply -f -
helm repo add chaos-mesh https://charts.chaos-mesh.org >/dev/null 2>&1
helm repo update >/dev/null 2>&1

log "Instalando Chaos Mesh..."
helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh \
  -f "$VALUES_DIR/chaos-mesh.values.yaml" --wait
