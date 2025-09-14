#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"
NS=app

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

log "Aplicando PriorityClasses e PDB"
kubectl apply -f "$MANIFESTS_DIR/priorityclasses.yaml"
PDB_MIN_AVAILABLE=${PDB_MIN_AVAILABLE:-2}
export PDB_MIN_AVAILABLE
envsubst < "$MANIFESTS_DIR/pdb.yaml" | kubectl -n "$NS" apply -f -

log "Deploy fortio server e client"
kubectl -n "$NS" apply -f "$MANIFESTS_DIR/app/service-fortio-server.yaml"
kubectl -n "$NS" apply -f "$MANIFESTS_DIR/app/deployment-fortio-server.yaml"
kubectl -n "$NS" apply -f "$MANIFESTS_DIR/app/service-fortio-client.yaml"
kubectl -n "$NS" apply -f "$MANIFESTS_DIR/app/deployment-fortio-client.yaml"
# HPA opcional
# kubectl -n "$NS" apply -f "$MANIFESTS_DIR/app/hpa-optional.yaml"
