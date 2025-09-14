# k8s-slo-resilience-lab

Repositório para experimentos de resiliência em Kubernetes orientados a SLOs.
Testado em Linux/WSL2 com Minikube (driver docker).

## Estrutura

```
scripts/                # automação dos passos
manifests/              # manifests Kubernetes e dashboards
helm-values/            # valores para charts Helm
tools/                  # utilitários auxiliares
results/                # saídas das coletas de métricas
```

## Pré-requisitos

- Docker
- Minikube \>= 1.32
- kubectl
- helm
- jq

Execute a verificação:

```bash
scripts/00_prereqs_check.sh
```

## Passos principais

1. `scripts/01_minikube_start.sh` – cria cluster com 4 nós e rotula/tainta os workers.
2. `scripts/02_install_observability.sh` – instala kube-prometheus-stack e provisiona dashboards.
3. `scripts/03_install_chaos_mesh.sh` – instala Chaos Mesh.
4. `scripts/04_deploy_app_stack.sh` – deploy do servidor e cliente Fortio.

### Experimentos

- `scripts/05_exp1_label_failure.sh` – injeta falha de etiquetamento para gerar pods Pending.
- `scripts/06_exp2_stress_and_failures.sh` – estressa nós e pausa o scheduler em três cenários de mitigação.

Os resultados são gravados em `results/`.

### Coleta e limpeza

- `scripts/90_collect_metrics.sh` – consulta o Prometheus e gera `results/summary.md`.
- `scripts/99_teardown.sh` – remove namespaces e deleta o cluster.

## SLOs

- Disponibilidade mensal ≥ 99.5% (orçamento de erro 0.5%).
- Latência p95 ≤ 200ms em janelas de 5min.

As consultas PromQL usadas encontram-se em `tools/export_promql.sh`.
