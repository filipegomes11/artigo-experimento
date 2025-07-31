# Experimento: Kubernetes QoS com PriorityClass, Stress Test e Monitoramento

Este experimento demonstra a resiliência do Kubernetes em ambientes com falhas de configuração e carga elevada, utilizando mecanismos como PriorityClass, nodeSelector e ferramentas de observabilidade como Prometheus e Grafana.

## Objetivos

- Simular erro de escalonamento causado por etiquetamento incorreto de nó (data plane)
- Corrigir o erro em tempo de execução e observar o comportamento do cluster
- Aplicar `PriorityClass` para priorização de pods críticos
- Aplicar teste de stress para simular ambiente de carga
- Instalar Prometheus e Grafana para observabilidade
- Validar a capacidade do Kubernetes de cumprir SLOs em cenário adverso

## Pré-requisitos

- Cluster Kubernetes local com dois nós (sugestão: Minikube com 2 nós)
- `kubectl` instalado e configurado
- `helm` instalado
- Acesso à internet para baixar charts do Helm

## Estrutura da pasta

- `priorityclass.yaml`: define uma PriorityClass de alta prioridade
- `critical-app.yaml`: deployment com pods que exigem label `node-type=correct`
- `stress-test.yaml`: job que aplica stress na CPU
- `run_full_experiment.sh`: script automatizado que executa todos os passos
- `README.md`: este documento com instruções

## Instruções de Execução

1. Inicie o Minikube com dois nós:

   ```bash
   minikube start --nodes 2
   ```

2. Dê permissão de execução para o script:

   ```bash
   chmod +x run_full_experiment.sh
   ```

3. Execute o experimento completo:

   ```bash
   ./run_full_experiment.sh
   ```

## Descrição do Experimento

1. Aplica um `Deployment` de aplicação crítica com `nodeSelector` que não encontra o nó correto (simula erro de etiquetamento)
2. Corrige a etiqueta do nó em tempo de execução
3. Os pods são realocados corretamente após a correção
4. Um `Job` de stress é iniciado, consumindo CPU
5. Prometheus e Grafana são instalados para coleta e visualização de métricas do cluster

## Acesso ao Grafana

Após a instalação automática via Helm, execute:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Acesse o Grafana em [http://localhost:3000](http://localhost:3000) com as credenciais padrão:

- Usuário: `admin`
- Senha: `prom-operator`

Dashboards podem ser criados para acompanhar métricas como:
- Uso de CPU por pod
- Número de pods em `Pending`
- Tempo de resposta médio
- Disponibilidade e falhas

## Resultados Esperados

- Inicialmente os pods ficarão em estado `Pending` por ausência da label `node-type=correct`
- Após a correção da etiqueta, os pods serão escalonados normalmente
- O job de stress simulará uso elevado de CPU no cluster
- Métricas serão visíveis no Grafana para validação de SLOs

## Considerações

Este experimento reproduz cenários reais de produção em ambientes heterogêneos e demonstra a importância de:

- Políticas de agendamento bem definidas (`nodeSelector`, `PriorityClass`)
- Observabilidade ativa com Prometheus e Grafana
- Estratégias de mitigação como correção dinâmica e resiliência via prioridades
- Análise dos impactos de falhas no cumprimento de SLOs definidos
