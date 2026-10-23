@echo off
REM ============================================================
REM KubeWatch - Port Forward Script
REM ============================================================
echo.
echo ============================================================
echo   KubeWatch - Starting Port Forwards
echo ============================================================
echo.
echo Starting port-forwarding for all services...
echo Press Ctrl+C to stop all port forwards.
echo.
echo Application:   http://localhost:8080
echo Prometheus:     http://localhost:9090
echo Grafana:        http://localhost:3000  (admin / kubewatch-admin)
echo Alertmanager:   http://localhost:9093
echo.

start "KubeWatch App" cmd /c "kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch"
start "Prometheus" cmd /c "kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring"
start "Grafana" cmd /c "kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"
start "Alertmanager" cmd /c "kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring"

echo All port-forwards started in separate windows.
echo Close the command windows to stop them.
