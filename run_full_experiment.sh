#!/bin/bash

set -e

echo "[1/10] Verificando e instalando dependências..."

if ! command -v kubectl &> /dev/null; then
    echo "Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

if ! command -v helm &> /dev/null; then
    echo "Instalando Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

if ! command -v minikube &> /dev/null; then
    echo "Instalando Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

echo "[2/10] Iniciando cluster Minikube com 2 nós..."
minikube delete > /dev/null 2>&1 || true
minikube start --nodes 2

echo "[3/10] Criando PriorityClass..."
kubectl apply -f priorityclass.yaml

echo "[4/10] Criando deployment com etiqueta incorreta..."
kubectl apply -f critical-app.yaml

echo "[5/10] Aguardando e verificando pods em Pending..."
sleep 10
kubectl get pods -l app=critical -o wide

echo "[6/10] Corrigindo etiqueta de nó..."
NODE=$(kubectl get nodes -o name | grep -v control-plane | head -n 1)
kubectl label $NODE node-type=correct --overwrite

echo "[7/10] Aguardando realocação dos pods..."
sleep 10
kubectl get pods -l app=critical -o wide

echo "[8/10] Aplicando job de stress..."
kubectl apply -f stress-test.yaml
sleep 5
kubectl get jobs

echo "[9/10] Instalando Prometheus e Grafana com Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

echo "[10/10] Aguardando readiness dos componentes de monitoramento..."
kubectl rollout status deployment prometheus-kube-prometheus-stack-grafana -n monitoring --timeout=120s
kubectl rollout status deployment prometheus-kube-prometheus-stack-prometheus -n monitoring --timeout=120s

echo ""
echo "=== EXPERIMENTO CONCLUÍDO ==="
echo "Para acessar o Grafana, execute:"
echo "kubectl port-forward svc/prometheus-kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "Depois acesse http://localhost:3000"
echo "Usuário: admin"
echo "Senha: prom-operator"
