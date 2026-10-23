@echo off
REM ============================================================
REM KubeWatch - Complete Setup Script for Windows 11
REM ============================================================
echo.
echo ============================================================
echo   KubeWatch - Complete Setup Script
echo ============================================================
echo.

REM --- Step 1: Start Minikube ---
echo [1/8] Starting Minikube...
minikube status >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting Minikube with Docker driver...
    minikube start --driver=docker --cpus=4 --memory=8192 --kubernetes-version=v1.28.0
) else (
    echo Minikube is already running.
)
echo.

REM --- Step 2: Enable Metrics Server ---
echo [2/8] Enabling metrics-server addon...
minikube addons enable metrics-server
echo.

REM --- Step 3: Build the Docker Image ---
echo [3/8] Building Docker image inside Minikube...
echo Setting Docker environment to Minikube...
@FOR /f "tokens=*" %%i IN ('minikube docker-env --shell cmd') DO @%%i

cd /d %~dp0\..\app
echo Building kubewatch-app:1.0.0...
docker build -t kubewatch-app:1.0.0 .
cd /d %~dp0
echo.

REM --- Step 4: Create Namespace ---
echo [4/8] Creating Kubernetes namespace...
kubectl apply -f %~dp0\..\k8s\namespace.yaml
echo.

REM --- Step 5: Deploy Application ---
echo [5/8] Deploying KubeWatch application...
kubectl apply -f %~dp0\..\k8s\configmap.yaml
kubectl apply -f %~dp0\..\k8s\deployment.yaml
kubectl apply -f %~dp0\..\k8s\service.yaml
kubectl apply -f %~dp0\..\k8s\hpa.yaml
echo.

REM --- Step 6: Install Monitoring Stack ---
echo [6/8] Installing monitoring stack with Helm...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack ^
  --namespace monitoring --create-namespace ^
  -f %~dp0\..\monitoring\values.yaml ^
  --wait --timeout 10m
echo.

REM --- Step 7: Apply ServiceMonitor and Alert Rules ---
echo [7/8] Applying ServiceMonitor and Prometheus alert rules...
kubectl apply -f %~dp0\..\monitoring\servicemonitor.yaml
kubectl apply -f %~dp0\..\monitoring\prometheus-rules.yaml
echo.

REM --- Step 8: Wait and Verify ---
echo [8/8] Waiting for pods to be ready...
kubectl wait --for=condition=ready pod -l app=kubewatch-app -n kubewatch --timeout=120s
echo.

echo ============================================================
echo   Setup Complete!
echo ============================================================
echo.
echo Access the application:
echo   kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch
echo   Open: http://localhost:8080
echo.
echo Access Grafana:
echo   kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
echo   Open: http://localhost:3000  (admin / kubewatch-admin)
echo.
echo Access Prometheus:
echo   kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
echo   Open: http://localhost:9090
echo.
echo Access Alertmanager:
echo   kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
echo   Open: http://localhost:9093
echo.
