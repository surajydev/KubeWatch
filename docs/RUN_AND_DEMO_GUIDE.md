# KubeWatch: Complete Run & Demonstration Master Guide

> **Project:** KubeWatch – Enterprise Kubernetes Monitoring & Alerting Platform  
> **Course:** INT334 – Enterprise Application Automation  
> **Environment:** Windows 11 (Minikube / Docker Desktop / Java 21 / Helm 3)

---

## 1. Prerequisites Check

Open PowerShell and verify:

```powershell
docker --version
minikube version
kubectl version --client
helm version
java -version
mvn -version
```

> **IMPORTANT:** Ensure **Docker Desktop is running** before proceeding.

---

## 2. Running the Project

### Option A: Automated (Fastest)

```powershell
cd d:\Project334
.\scripts\setup.bat
```

### Option B: Manual Step-by-Step

#### Step 1: Start Minikube & Enable Metrics
```powershell
minikube start --driver=docker --cpus=4 --memory=8192 --kubernetes-version=v1.28.0
minikube addons enable metrics-server
```

#### Step 2: Build App Docker Image in Minikube's Daemon
```powershell
minikube docker-env --shell powershell | Invoke-Expression
cd d:\Project334\app
docker build -t kubewatch-app:1.0.0 .
cd d:\Project334
```

#### Step 3: Deploy Application Resources
```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

#### Step 4: Install Monitoring Stack (Prometheus + Grafana + Alertmanager)
```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack `
  --namespace monitoring --create-namespace `
  -f monitoring/values.yaml `
  --wait --timeout 10m

kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/prometheus-rules.yaml
```

#### Step 5: Verify Everything is Running
```powershell
kubectl get pods -n kubewatch
kubectl get pods -n monitoring
```
*Wait until all pods show `Running` and `1/1` (or `2/2`) status.*

---

## 3. Starting Port Forwarding

Run the script:
```powershell
.\scripts\port-forward.bat
```

*Or run these in 4 separate terminal windows:*

| Service | Local URL | Port-Forward Command |
|---|---|---|
| **Spring Boot App** | http://localhost:8080 | `kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch` |
| **Prometheus** | http://localhost:9090 | `kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring` |
| **Grafana** | http://localhost:3000 | `kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring` |
| **Alertmanager** | http://localhost:9093 | `kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring` |

> **Grafana Login:**  
> **Username:** `admin`  
> **Password:** `kubewatch-admin`

---

## 4. Live Demonstration Walkthrough (Step-by-Step for Examiner)

### Demo 1: Show Deployed Pods, Services & HPA
**What to say:** *"The Spring Boot microservice is deployed with 2 replicas, health probes, and auto-scaling configured."*
```powershell
kubectl get pods -n kubewatch -o wide
kubectl get svc -n kubewatch
kubectl get hpa -n kubewatch
kubectl get deployments -n kubewatch
```

---

### Demo 2: Demonstrate Microservice Endpoints
**What to say:** *"The application exposes operational endpoints and custom instrumentation via Spring Boot Actuator and Micrometer."*

Open in browser:
1. **Welcome API:** `http://localhost:8080/`
2. **Health & JVM Info:** `http://localhost:8080/api/health`
3. **Simulated Workload:** `http://localhost:8080/api/metrics-demo` (generates custom counter increments)
4. **Error Simulation:** `http://localhost:8080/api/error-demo` (returns HTTP 500)
5. **Actuator Health:** `http://localhost:8080/actuator/health`
6. **Raw Prometheus Metrics:** `http://localhost:8080/actuator/prometheus`
   - *Highlight custom metrics:* `kubewatch_requests_total`, `kubewatch_errors_total`, and `jvm_memory_used_bytes`.

---

### Demo 3: Prometheus Target Discovery & PromQL
**What to say:** *"Prometheus uses our ServiceMonitor CRD to automatically discover and scrape the pods every 15 seconds."*

1. Open `http://localhost:9090` -> Click **Status** -> **Targets**.
2. Show `serviceMonitor/kubewatch/kubewatch-app-monitor/0` showing status **UP**.
3. Go to **Graph** and run sample queries:
   ```promql
   up{job="kubewatch-app"}
   ```
   *(Returns 1 for each pod)*
   ```promql
   http_server_requests_seconds_count{application="kubewatch-app"}
   ```

---

### Demo 4: Grafana Dashboard Visualization
**What to say:** *"Grafana connects to Prometheus to render unified application, JVM, and Kubernetes cluster telemetry."*

1. Open `http://localhost:3000` (Login: `admin` / `kubewatch-admin`).
2. Navigate to **Dashboards** -> **Import** -> Click **Upload JSON file**.
3. Select `d:\Project334\monitoring\grafana-dashboards\kubewatch-dashboard.json`.
4. Pick **Prometheus** datasource -> Click **Import**.
5. Show live panels:
   - Application Status & Ready Pods
   - HTTP Request Rates & Error Rate
   - P95 Latency & Response Codes (4xx/5xx)
   - JVM Heap & Non-Heap Memory
   - Container CPU & Working Set Memory

---

### Demo 5: Generate Traffic & Watch Live Dashboard Updates
**What to say:** *"Let's generate synthetic traffic and watch the telemetry reflect real-time load."*

In a new terminal:
```powershell
for ($i=1; $i -le 100; $i++) {
    Invoke-WebRequest -Uri http://localhost:8080/api/metrics-demo -UseBasicParsing | Out-Null
    Write-Host "Request $i sent"
}
```
*Switch to Grafana: point to the instant spike in HTTP Request Rate.*

---

### Demo 6: Error Injection & Alert Triggering
**What to say:** *"I will trigger sustained 500 errors to test our alerting threshold."*

In PowerShell:
```powershell
for ($i=1; $i -le 50; $i++) {
    try { Invoke-WebRequest -Uri http://localhost:8080/api/error-demo -UseBasicParsing } catch {}
    Write-Host "Error $i triggered"
}
```

1. Open Prometheus Alerts: `http://localhost:9090/alerts`
2. Show `KubeWatchAppHighErrorRate` moving from `Pending` -> `Firing`.
3. Open Alertmanager: `http://localhost:9093` to show the routed alert.

---

### Demo 7: Self-Healing / Pod Auto-Recovery
**What to say:** *"Kubernetes maintains our desired replica count automatically if a container or pod dies."*

```powershell
# Get current pod names
kubectl get pods -n kubewatch

# Force delete a pod
kubectl delete pod -l app=kubewatch-app -n kubewatch --wait=false

# Watch real-time replacement
kubectl get pods -n kubewatch -w
```
*(Press `Ctrl+C` once new pod is Running)*

---

### Demo 8: Manual & Auto-Scaling (HPA)
**What to say:** *"We can scale pods manually, and HPA scales them automatically between 2 and 5 replicas based on CPU/Memory load."*

```powershell
# Scale up to 4 replicas
kubectl scale deployment kubewatch-app --replicas=4 -n kubewatch
kubectl get pods -n kubewatch

# Scale back to 2 replicas
kubectl scale deployment kubewatch-app --replicas=2 -n kubewatch
kubectl get pods -n kubewatch
```

---

### Demo 9: Zero-Downtime Rolling Update
**What to say:** *"Rolling updates ensure continuous availability during application version releases."*

```powershell
kubectl set image deployment/kubewatch-app kubewatch-app=kubewatch-app:1.0.0 -n kubewatch
kubectl rollout status deployment/kubewatch-app -n kubewatch
kubectl rollout history deployment/kubewatch-app -n kubewatch
```

---

### Demo 10: Complete Outage (AppDown Alert)
**What to say:** *"If all replicas crash or fail, Prometheus immediately fires a Critical AppDown alert."*

```powershell
# Scale to 0 replicas
kubectl scale deployment kubewatch-app --replicas=0 -n kubewatch

# Wait 60s and check Prometheus:
# http://localhost:9090/alerts -> KubeWatchAppDown FIRING

# Restore application
kubectl scale deployment kubewatch-app --replicas=2 -n kubewatch
kubectl wait --for=condition=ready pod -l app=kubewatch-app -n kubewatch --timeout=120s
```

*(Restart `kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch` if the connection dropped).*

---

### Demo 11: Frontend UI Overview
Open `d:\Project334\frontend\index.html` (or your live Vercel URL) in the browser to showcase the web dashboard UI presentation.

---

## 5. Viva Defense Quick Reference

| Question | Strong Technical Answer |
|---|---|
| **What is KubeWatch?** | An enterprise observability and deployment architecture featuring a Spring Boot 3.2 microservice orchestrated via Kubernetes, scraped by Prometheus using Operator ServiceMonitors, visualized in Grafana, and alerted via Alertmanager. |
| **Why use a ServiceMonitor instead of static scrape configs?** | ServiceMonitors are Kubernetes CRDs managed by the Prometheus Operator. They enable declarative, label-based auto-discovery of endpoints across namespaces without modifying the central Prometheus configuration file. |
| **How do Health Probes work here?** | We configure Startup (delay 15s), Liveness (`/actuator/health/liveness`), and Readiness (`/actuator/health/readiness`) probes. Startup handles JVM boot time, readiness gates ingress routing, and liveness restarts deadlocked pods. |
| **What does HPA monitor?** | It polls Metrics Server for pod CPU and memory utilization, scaling between 2 to 5 pods when CPU exceeds 70% or memory exceeds 80%. |
| **What are the custom metrics?** | We use Micrometer's `Counter` (`kubewatch_requests_total`, `kubewatch_errors_total`) and `Timer` (`kubewatch_processing_duration`) to measure business-logic telemetry directly alongside standard HTTP and JVM metrics. |
| **How does multi-stage Docker build help?** | Stage 1 (JDK 21) builds the fat JAR; Stage 2 (lightweight JRE Alpine) runs it under an unprivileged user. It shrinks image footprint and eliminates build tools from production. |

---

## 6. Shutdown / Teardown

To cleanly shut down after the presentation:

```powershell
cd d:\Project334
.\scripts\cleanup.bat
minikube stop
```
