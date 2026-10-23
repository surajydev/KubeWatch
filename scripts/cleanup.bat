@echo off
REM ============================================================
REM KubeWatch - Cleanup Script
REM ============================================================
echo.
echo ============================================================
echo   KubeWatch - Cleanup
echo ============================================================
echo.

echo [1/5] Uninstalling monitoring stack...
helm uninstall monitoring -n monitoring 2>nul
echo.

echo [2/5] Uninstalling kubewatch-app Helm release...
helm uninstall kubewatch-app -n kubewatch 2>nul
echo.

echo [3/5] Deleting Kubernetes resources...
kubectl delete -f %~dp0\..\monitoring\prometheus-rules.yaml 2>nul
kubectl delete -f %~dp0\..\monitoring\servicemonitor.yaml 2>nul
kubectl delete -f %~dp0\..\k8s\hpa.yaml 2>nul
kubectl delete -f %~dp0\..\k8s\deployment.yaml 2>nul
kubectl delete -f %~dp0\..\k8s\service.yaml 2>nul
kubectl delete -f %~dp0\..\k8s\configmap.yaml 2>nul
echo.

echo [4/5] Deleting namespaces...
kubectl delete namespace kubewatch 2>nul
kubectl delete namespace monitoring 2>nul
echo.

echo [5/5] Optionally stop Minikube...
echo To stop Minikube, run: minikube stop
echo To delete Minikube, run: minikube delete
echo.

echo ============================================================
echo   Cleanup Complete
echo ============================================================
