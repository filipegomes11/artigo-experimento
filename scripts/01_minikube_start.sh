#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE=${MINIKUBE_PROFILE:-slo-lab}
NODES=${NODES:-4}

log "Iniciando Minikube ($PROFILE) com $NODES nós..."
minikube start -p "$PROFILE" --driver=docker --nodes="$NODES" --addons=metrics-server

log "Aguardando nós ficarem prontos..."
kubectl wait nodes --for=condition=Ready --all --timeout=300s

log "Rotulando e aplicando taints nos nós"
"$SCRIPT_DIR/../tools/label_nodes.sh" "$PROFILE"

log "Cluster pronto"
