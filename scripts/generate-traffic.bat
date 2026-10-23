@echo off
REM ============================================================
REM KubeWatch - Demo Script for Generating Test Traffic
REM ============================================================
echo.
echo ============================================================
echo   KubeWatch - Generating Test Traffic
echo ============================================================
echo.
echo Make sure port-forward is running for the application on port 8080.
echo.

echo --- Testing Home Endpoint ---
curl -s http://localhost:8080/ | findstr /i "KubeWatch"
echo.

echo --- Testing Health Endpoint ---
curl -s http://localhost:8080/api/health | findstr /i "UP"
echo.

echo --- Generating Metrics Demo Traffic (20 requests) ---
for /L %%i in (1,1,20) do (
    curl -s -o nul http://localhost:8080/api/metrics-demo
    echo   Request %%i sent
)
echo.

echo --- Generating Error Traffic (10 requests for alert testing) ---
for /L %%i in (1,1,10) do (
    curl -s -o nul http://localhost:8080/api/error-demo
    echo   Error request %%i sent
)
echo.

echo --- Checking Prometheus Metrics ---
curl -s http://localhost:8080/actuator/prometheus | findstr /i "kubewatch"
echo.

echo ============================================================
echo   Test Traffic Generated
echo   Check Grafana dashboard for updated metrics.
echo   Check Alertmanager for fired alerts.
echo ============================================================
