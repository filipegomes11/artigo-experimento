#!/usr/bin/env bash
set -euo pipefail
cat <<'QEOF'
p95: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="fortio-server"}[5m])) by (le))
http_5xx_rate: sum(rate(http_requests_total{status=~"5.."}[5m]))
availability: 1 - (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])))
pending_pods: sum(kube_pod_status_phase{phase="Pending", namespace="app"})
evicted_pods: sum(kube_pod_status_reason{reason="Evicted", namespace="app"})
scheduling_latency_p95: histogram_quantile(0.95,sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket[5m])) by (le))
QEOF
