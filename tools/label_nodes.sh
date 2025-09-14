#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[$(date +%F' '%T)] $*"; }
PROFILE=${1:-slo-lab}

workers=($(kubectl get nodes --no-headers | awk '!/control-plane/ {print $1}'))
if [ "${#workers[@]}" -lt 3 ]; then
  log "É necessário pelo menos 3 nós workers"
  exit 1
fi

kubectl label nodes "${workers[0]}" node=worker-a hw=gen1 zone=a --overwrite
kubectl label nodes "${workers[1]}" node=worker-b hw=gen2 zone=b --overwrite
kubectl label nodes "${workers[2]}" node=worker-c hw=legacy --overwrite
kubectl taint nodes "${workers[2]}" hw=legacy:NoSchedule --overwrite

log "Nós rotulados"
kubectl get nodes -L node,hw,zone
