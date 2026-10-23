@echo off
REM ============================================================
REM KubeWatch - Verification Script
REM ============================================================
echo.
echo ============================================================
echo   KubeWatch - System Verification
echo ============================================================
echo.

echo --- Prerequisites ---
echo.
echo Java version:
java -version 2>&1 | findstr /i "version"
echo.
echo Maven version:
mvn -version 2>&1 | findstr /i "Apache Maven"
echo.
echo Docker version:
docker --version
echo.
echo kubectl version:
kubectl version --client --short 2>nul || kubectl version --client
echo.
echo Minikube version:
minikube version
echo.
echo Helm version:
helm version --short
echo.

echo --- Kubernetes Cluster ---
echo.
echo Cluster info:
kubectl cluster-info 2>nul
echo.

echo --- KubeWatch Namespace ---
echo.
echo Pods:
kubectl get pods -n kubewatch -o wide
echo.
echo Services:
kubectl get svc -n kubewatch
echo.
echo Deployments:
kubectl get deployments -n kubewatch
echo.
echo HPA:
kubectl get hpa -n kubewatch
echo.

echo --- Monitoring Namespace ---
echo.
echo Pods:
kubectl get pods -n monitoring
echo.
echo Services:
kubectl get svc -n monitoring
echo.

echo --- Helm Releases ---
echo.
helm list -A
echo.

echo --- ServiceMonitors ---
echo.
kubectl get servicemonitors -n kubewatch 2>nul || echo "No ServiceMonitors found (CRD may not be installed yet)"
echo.

echo --- Prometheus Rules ---
echo.
kubectl get prometheusrules -n kubewatch 2>nul || echo "No PrometheusRules found (CRD may not be installed yet)"
echo.

echo ============================================================
echo   Verification Complete
echo ============================================================
