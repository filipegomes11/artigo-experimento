#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }

check_cmd(){
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERR: comando '$1' não encontrado"
    exit 1
  fi
}

check_cmd docker
check_cmd minikube
check_cmd kubectl
check_cmd helm
check_cmd jq

required="1.32.0"
ver=$(minikube version --short 2>/dev/null | head -n1)
if [ "$(printf '%s\n' "$required" "$ver" | sort -V | head -n1)" != "$required" ]; then
  log "ERR: minikube >= $required requerido, versão atual: $ver"
  exit 1
fi

log "Pré-requisitos ok"
