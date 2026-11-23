# KubeWatch — Full Demonstration Guide (Step by Step)

> **Course:** INT334 – Enterprise Application Automation  
> **Total Demo Time:** ~20–25 minutes  
> **Prerequisite:** Docker Desktop must be running before you begin

---

## ⏱ BEFORE THE DEMO (Do This 30 Minutes Early)

---

### Step 1: Verify All Tools Are Installed

Open PowerShell and run:

```powershell
java -version
mvn -version
docker --version
minikube version
kubectl version --client
helm version
```

All 6 commands should return version numbers without errors.

---

### Step 2: Start Minikube Cluster

```powershell
minikube start --driver=docker --cpus=4 --memory=8192 --kubernetes-version=v1.28.0
```

Wait until you see "Done! kubectl is now configured to use minikube cluster".

Then enable the metrics server:

```powershell
minikube addons enable metrics-server
```

---

### Step 3: Build the Docker Image Inside Minikube

```powershell
# Connect Docker CLI to Minikube's Docker daemon
minikube docker-env --shell powershell | Invoke-Expression

# Navigate to the app folder and build
cd d:\Project334\app
docker build -t kubewatch-app:1.0.0 .

# Go back to project root
cd d:\Project334
```

You should see "Successfully tagged kubewatch-app:1.0.0".

---

### Step 4: Deploy Application to Kubernetes

Run these commands one by one:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

---

### Step 5: Install Monitoring Stack (Prometheus + Grafana + Alertmanager)

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack ^
  --namespace monitoring --create-namespace ^
  -f monitoring/values.yaml ^
  --wait --timeout 10m
```

> **Note:** This step takes 3–5 minutes. Wait until it says "has been upgraded" or "has been installed".

Then apply our custom monitoring configs:

```powershell
kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/prometheus-rules.yaml
```

---

### Step 6: Wait for All Pods to Be Ready

```powershell
kubectl wait --for=condition=ready pod -l app=kubewatch-app -n kubewatch --timeout=120s
```

Verify everything is running:

```powershell
kubectl get pods -n kubewatch
kubectl get pods -n monitoring
```

All pods should show `Running` and `1/1 READY`.

---

### Step 7: Start Port Forwarding

Open **4 separate PowerShell terminals** and run one command in each:

**Terminal 1 (Application):**
```powershell
kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch
```

**Terminal 2 (Prometheus):**
```powershell
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
```

**Terminal 3 (Grafana):**
```powershell
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

**Terminal 4 (Alertmanager):**
```powershell
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
```

**Keep all 4 terminals open throughout the demo.**

---

## 🎯 THE ACTUAL DEMONSTRATION (Show This to Examiner)

---

### Demo 1: Show Kubernetes Deployment Status

**What to tell the examiner:**  
_"I have deployed a Spring Boot application on Kubernetes with 2 replicas, a ClusterIP service, and a Horizontal Pod Autoscaler."_

Open a new terminal and run:

```powershell
kubectl get pods -n kubewatch -o wide
```

**Expected output:**
```
NAME                             READY   STATUS    RESTARTS   AGE
kubewatch-app-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
kubewatch-app-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

Then show the service and HPA:

```powershell
kubectl get svc -n kubewatch
kubectl get hpa -n kubewatch
kubectl get deployments -n kubewatch
```

---

### Demo 2: Show Application REST Endpoints

**What to tell the examiner:**  
_"The application exposes multiple REST endpoints. Let me hit each one."_

Open your browser and visit these URLs one by one:

**URL 1:** http://localhost:8080  
→ Shows: `{"application":"KubeWatch","version":"1.0.0","message":"Welcome to KubeWatch..."}`

**URL 2:** http://localhost:8080/api/health  
→ Shows: Application health with JVM memory info, hostname, processors

**URL 3:** http://localhost:8080/api/metrics-demo  
→ Shows: `{"status":"processed"}` — this simulates workload and increments custom metrics

**URL 4:** http://localhost:8080/api/error-demo  
→ Shows: `{"status":"error","code":500}` — this simulates a server error for alert testing

**URL 5:** http://localhost:8080/actuator/health  
→ Shows: Spring Boot Actuator health check (`{"status":"UP"}`)

**URL 6:** http://localhost:8080/actuator/prometheus  
→ Shows: Raw Prometheus metrics (scroll through this page)

**Point out these metrics on the `/actuator/prometheus` page:**
- Search for `kubewatch_errors_total` → our custom error counter
- Search for `kubewatch_requests_total` → our custom request counter  
- Search for `jvm_memory_used_bytes` → JVM memory metrics
- Search for `http_server_requests_seconds_count` → HTTP request metrics from Micrometer

**What to tell the examiner:**  
_"These metrics are exposed by Spring Boot Actuator using Micrometer in Prometheus format. Prometheus scrapes this endpoint automatically."_

---

### Demo 3: Show Prometheus Targets (Scrape Verification)

**What to tell the examiner:**  
_"Prometheus discovers our application automatically through a ServiceMonitor CRD and scrapes metrics every 15 seconds."_

1. Open http://localhost:9090 in browser
2. Click **Status** in the top menu → click **Targets**
3. Find the target: `serviceMonitor/kubewatch/kubewatch-app-monitor/0`
4. Status should show **UP** in green

**Then run a PromQL query:**

1. Go to http://localhost:9090/graph
2. Type in the query box:
   ```
   up{job="kubewatch-app"}
   ```
3. Click **Execute**
4. Result should show value `1` (meaning the app is UP)

**Run one more query:**
```
http_server_requests_seconds_count{application="kubewatch-app"}
```

**What to tell the examiner:**  
_"The value 1 means our application is UP and being scraped by Prometheus. The ServiceMonitor tells Prometheus where to find our app."_

---

### Demo 4: Show Grafana Dashboard

**What to tell the examiner:**  
_"Grafana connects to Prometheus as a data source and displays dashboards with real-time metrics."_

1. Open http://localhost:3000 in browser
2. Login with:
   - Username: `admin`
   - Password: `kubewatch-admin`
3. Click the **hamburger menu (☰)** on the left → **Dashboards** → **Import**
4. Click **Upload JSON file**
5. Navigate to `d:\Project334\monitoring\grafana-dashboards\kubewatch-dashboard.json`
6. Select **Prometheus** as the data source dropdown
7. Click **Import**

**Walk through the dashboard panels:**

| Panel | What it shows |
|-------|---------------|
| Application Status | UP/DOWN indicator |
| Running Pods | Number of ready pods |
| Pod Restarts (Last 1h) | Container restart count |
| Error Rate (5xx/total) | Percentage of 5xx errors |
| HTTP Request Rate | Requests per second by URI |
| HTTP Response Latency (p95) | 95th percentile response time |
| HTTP 4xx & 5xx Responses | Error responses per second |
| Custom Metrics | kubewatch_requests_total and kubewatch_errors_total |
| JVM Heap Memory | Used, max, committed heap memory |
| JVM Non-Heap Memory | Used and committed non-heap |
| Pod CPU Usage | CPU usage per pod |
| Pod Memory Usage | Memory usage per pod |

**Bonus — show built-in Kubernetes dashboards:**
- Go to **Dashboards → Browse**
- Open **"Kubernetes / Compute Resources / Namespace (Pods)"**
- Select namespace: `kubewatch`

---

### Demo 5: Generate Traffic and Watch Metrics Update in Real-Time

**What to tell the examiner:**  
_"I'll generate traffic to the application and you can see the metrics update live in Grafana."_

Open a new terminal and run:

```powershell
for ($i=1; $i -le 100; $i++) {
    Invoke-WebRequest -Uri http://localhost:8080/api/metrics-demo -UseBasicParsing | Out-Null
    Write-Host "Request $i sent"
}
```

**Now immediately switch to:**
1. **Grafana** → The "HTTP Request Rate" panel should show a spike
2. **Prometheus** → Run query: `rate(http_server_requests_seconds_count{application="kubewatch-app"}[1m])` to see the rate

**What to tell the examiner:**  
_"You can see the request rate spiking in real-time. Prometheus scrapes every 15 seconds and Grafana auto-refreshes."_

---

### Demo 6: Trigger Errors and Show Alert Firing

**What to tell the examiner:**  
_"I'll simulate server errors to trigger the High Error Rate alert."_

Run this in terminal:

```powershell
for ($i=1; $i -le 50; $i++) {
    try { Invoke-WebRequest -Uri http://localhost:8080/api/error-demo -UseBasicParsing } catch {}
    Write-Host "Error request $i sent"
}
```

**Then show:**

1. Open http://localhost:9090/alerts
2. Find **KubeWatchAppHighErrorRate**
3. It will transition: `inactive` → `pending` → `firing` (may take 2–3 min)

4. Open http://localhost:9093
5. The fired alert should appear in the Alertmanager UI

**What to tell the examiner:**  
_"The alert rule detects when more than 10% of requests return 5xx errors. Prometheus evaluates this rule, and when the condition is met, it fires to Alertmanager."_

---

### Demo 7: Pod Self-Healing (Auto Recovery)

**What to tell the examiner:**  
_"Kubernetes automatically recovers crashed or deleted pods. Watch this."_

```powershell
# Show current pods
kubectl get pods -n kubewatch
```

Note the pod names. Then:

```powershell
# Delete one pod
kubectl delete pod -l app=kubewatch-app -n kubewatch --wait=false

# Watch recovery happen in real-time
kubectl get pods -n kubewatch -w
```

**Expected behavior:**
- The old pod goes to `Terminating`
- A new pod immediately appears with status `ContainerCreating` → `Running`
- Total pod count stays at 2 (the desired replica count)

Press `Ctrl+C` to stop watching.

**What to tell the examiner:**  
_"The Deployment controller detects the pod was deleted and immediately creates a new one to maintain the desired replica count of 2."_

---

### Demo 8: Manual Scaling

**What to tell the examiner:**  
_"We can scale the application up or down. The HPA also handles auto-scaling based on CPU and memory thresholds."_

**Scale up:**
```powershell
kubectl scale deployment kubewatch-app --replicas=4 -n kubewatch
kubectl get pods -n kubewatch -w
```

Wait until all 4 pods show `Running`. Press `Ctrl+C`.

```powershell
# Check HPA
kubectl get hpa -n kubewatch
```

**Scale back down:**
```powershell
kubectl scale deployment kubewatch-app --replicas=2 -n kubewatch
kubectl get pods -n kubewatch -w
```

Press `Ctrl+C` after pods stabilize.

**What to tell the examiner:**  
_"The HPA is configured to auto-scale between 2 and 5 replicas when CPU exceeds 70% or memory exceeds 80%. We also demonstrated manual scaling."_

---

### Demo 9: Rolling Update (Zero-Downtime Deployment)

**What to tell the examiner:**  
_"Kubernetes supports rolling updates for zero-downtime deployments."_

```powershell
# Trigger a rolling update
kubectl set image deployment/kubewatch-app kubewatch-app=kubewatch-app:1.0.0 -n kubewatch

# Watch the rollout
kubectl rollout status deployment/kubewatch-app -n kubewatch

# View rollout history
kubectl rollout history deployment/kubewatch-app -n kubewatch
```

**What to tell the examiner:**  
_"During a rolling update, Kubernetes replaces old pods one at a time. Our config allows max 1 unavailable and 1 surge pod. The application stays available throughout."_

---

### Demo 10: Show All 7 Alert Rules

**What to tell the examiner:**  
_"We have 7 custom Prometheus alert rules for production-level monitoring."_

```powershell
kubectl get prometheusrules -n kubewatch
kubectl describe prometheusrule kubewatch-alerts -n kubewatch
```

Also open http://localhost:9090/alerts to show all rules in the UI.

**List the 7 alerts:**

| Alert | Condition | Severity |
|-------|-----------|----------|
| KubeWatchAppDown | App unreachable for 1 min | Critical |
| KubeWatchAppHighErrorRate | >10% 5xx errors for 2 min | Warning |
| KubeWatchHighCPU | >80% CPU for 5 min | Warning |
| KubeWatchHighMemory | >85% memory for 5 min | Warning |
| KubeWatchPodRestarting | >3 restarts in 1 hour | Critical |
| KubeWatchPodNotReady | Not ready for 5 min | Warning |
| KubeWatchJVMHeapHigh | >90% JVM heap for 5 min | Warning |

---

### Demo 11 (Bonus): Trigger App Down Alert

**What to tell the examiner:**  
_"Watch what happens when the entire application goes down."_

```powershell
# Scale to 0 replicas (simulates complete outage)
kubectl scale deployment kubewatch-app --replicas=0 -n kubewatch
```

Wait 1–2 minutes, then check:
- http://localhost:9090/alerts → `KubeWatchAppDown` should be `FIRING`
- http://localhost:9093 → Alert visible in Alertmanager

**Restore the application:**
```powershell
kubectl scale deployment kubewatch-app --replicas=2 -n kubewatch
kubectl wait --for=condition=ready pod -l app=kubewatch-app -n kubewatch --timeout=120s
```

**Important:** After restoring, restart the application port-forward (the old one breaks):
```powershell
kubectl port-forward svc/kubewatch-app 8080:8080 -n kubewatch
```

---

### Demo 12: Show Application Logs

**What to tell the examiner:**  
_"We can view application logs directly from Kubernetes."_

```powershell
# View logs from all pods
kubectl logs -l app=kubewatch-app -n kubewatch --tail=20

# View Kubernetes events
kubectl get events -n kubewatch --sort-by=.metadata.creationTimestamp
```

---

### Demo 13: Show the Frontend Dashboard

**What to tell the examiner:**  
_"We also have a static frontend dashboard that shows the monitoring overview UI."_

Open `d:\Project334\frontend\index.html` directly in your browser (just double-click the file).

This shows a polished dashboard with:
- Cluster health status
- CPU and Memory usage cards
- Running pods count
- Resource usage chart (SVG)
- Application status panel
- Recent alerts list
- Workloads table

---

## 🧹 AFTER THE DEMO (Cleanup)

```powershell
.\scripts\cleanup.bat
minikube stop
```

---

## 🆘 TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| Pods stuck in `ImagePullBackOff` | Run `minikube docker-env --shell powershell \| Invoke-Expression` and rebuild the Docker image |
| Pod in `CrashLoopBackOff` | Check logs: `kubectl logs <pod-name> -n kubewatch` |
| Port-forward disconnects | Re-run the port-forward command in that terminal |
| Prometheus target not showing | Wait 1–2 minutes, it auto-discovers. Check: `kubectl get servicemonitors -n kubewatch` |
| Grafana login fails | Username: `admin` / Password: `kubewatch-admin` |
| HPA shows `<unknown>` targets | Run: `minikube addons enable metrics-server` and wait 2 min |
| Minikube won't start | Run `minikube delete` then start fresh |
| Docker build fails | Make sure Docker Desktop is running |

---

## 🎤 VIVA QUESTIONS & ANSWERS

**Q: Explain the architecture of your project.**  
A: KubeWatch is a Spring Boot 3.2 application containerized with Docker and deployed on a Kubernetes cluster using Minikube. The app exposes REST endpoints and uses Spring Boot Actuator with Micrometer to export metrics in Prometheus format at `/actuator/prometheus`. A ServiceMonitor CRD tells Prometheus where to scrape. Prometheus stores the metrics and feeds Grafana for visualization. Alertmanager receives alerts when defined thresholds are breached. The deployment uses 2 replicas with rolling updates, health probes, and an HPA for auto-scaling.

**Q: What is a ServiceMonitor?**  
A: A Custom Resource Definition (CRD) from the Prometheus Operator. It auto-configures Prometheus to scrape specific Kubernetes services by matching labels, instead of manually editing Prometheus config files.

**Q: What is Micrometer?**  
A: Micrometer is a metrics instrumentation library for JVM applications. It acts as a bridge between Spring Boot Actuator and monitoring backends like Prometheus. We use it to register custom counters (kubewatch_errors_total, kubewatch_requests_total) and timers (kubewatch_processing_duration).

**Q: What are Kubernetes health probes?**  
A: Three types — Startup Probe (gives app time to start), Readiness Probe (checks if app can accept traffic), Liveness Probe (checks if app is alive, restarts if not). We use HTTP GET checks against Actuator endpoints.

**Q: What is HPA?**  
A: Horizontal Pod Autoscaler. It automatically adjusts the number of pod replicas based on observed CPU/memory utilization. Ours scales between 2–5 replicas when CPU > 70% or memory > 80%.

**Q: Why Helm?**  
A: Helm is a Kubernetes package manager. We use it to install the entire kube-prometheus-stack (Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics) with one command and a custom values.yaml file. We also have our own Helm chart for the KubeWatch app.

**Q: What is a rolling update?**  
A: A deployment strategy that replaces old pods with new ones incrementally. Our config allows max 1 unavailable and 1 extra (surge) pod during updates, ensuring the application stays available throughout.

**Q: What monitoring metrics are you collecting?**  
A: Application metrics (HTTP request rate, response latency, error rate, custom counters), JVM metrics (heap/non-heap memory, garbage collection), Kubernetes metrics (pod CPU/memory, restarts, readiness), and infrastructure metrics (node CPU, memory, disk via Node Exporter).

**Q: How does alerting work?**  
A: We define PrometheusRule resources with PromQL expressions. Prometheus evaluates these rules periodically. When a condition is true for the specified duration, Prometheus fires the alert to Alertmanager. Alertmanager groups, routes, and can send notifications (email, Slack, webhooks).

**Q: What is the multi-stage Docker build?**  
A: Our Dockerfile uses two stages. Stage 1 (builder) uses a JDK image to compile the app with Maven. Stage 2 (runtime) uses a lightweight JRE image and copies only the built JAR. This reduces the final image size significantly and doesn't include build tools in production.

---

## 📋 DEMO CHECKLIST (Tick as you go)

- [ ] Pods running in Kubernetes (`kubectl get pods`)
- [ ] REST endpoints responding (hit each URL in browser)
- [ ] Prometheus targets showing UP
- [ ] Grafana dashboard imported and showing panels
- [ ] Generated traffic, saw metrics update in Grafana
- [ ] Triggered errors, saw error rate spike
- [ ] Showed alert firing in Prometheus/Alertmanager
- [ ] Deleted a pod, showed auto-recovery
- [ ] Scaled replicas up and down
- [ ] Showed rolling update
- [ ] Showed alert rules (7 total)
- [ ] Showed application logs
- [ ] Showed frontend dashboard
