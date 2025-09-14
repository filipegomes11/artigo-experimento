#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
PROFILE=${MINIKUBE_PROFILE:-slo-lab}

log "Removendo namespaces"
kubectl delete ns app chaos-mesh observability --ignore-not-found

log "Deletando cluster Minikube"
minikube delete -p "$PROFILE" -y
