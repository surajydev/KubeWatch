package com.kubewatch.controller;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.InetAddress;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@RestController
public class HomeController {

    private final Counter errorCounter;
    private final Counter requestCounter;
    private final Timer metricsTimer;

    public HomeController(MeterRegistry registry) {
        this.errorCounter = Counter.builder("kubewatch_errors_total")
                .description("Total simulated errors")
                .tag("type", "demo")
                .register(registry);

        this.requestCounter = Counter.builder("kubewatch_requests_total")
                .description("Total requests to demo endpoints")
                .tag("endpoint", "metrics-demo")
                .register(registry);

        this.metricsTimer = Timer.builder("kubewatch_processing_duration")
                .description("Processing duration for metrics demo")
                .tag("endpoint", "metrics-demo")
                .register(registry);
    }

    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> home() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("application", "KubeWatch");
        response.put("version", "1.0.0");
        response.put("message", "Welcome to KubeWatch - Kubernetes Monitoring Platform");
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "UP");
        response.put("application", "kubewatch-app");
        response.put("timestamp", Instant.now().toString());

        try {
            response.put("hostname", InetAddress.getLocalHost().getHostName());
        } catch (Exception e) {
            response.put("hostname", "unknown");
        }

        // JVM info
        Runtime rt = Runtime.getRuntime();
        Map<String, Object> jvm = new LinkedHashMap<>();
        jvm.put("maxMemoryMB", rt.maxMemory() / (1024 * 1024));
        jvm.put("totalMemoryMB", rt.totalMemory() / (1024 * 1024));
        jvm.put("freeMemoryMB", rt.freeMemory() / (1024 * 1024));
        jvm.put("availableProcessors", rt.availableProcessors());
        response.put("jvm", jvm);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/metrics-demo")
    public ResponseEntity<Map<String, Object>> metricsDemo() {
        return metricsTimer.record(() -> {
            requestCounter.increment();

            // Simulate processing (10-100ms)
            try {
                Thread.sleep(ThreadLocalRandom.current().nextInt(10, 100));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            Map<String, Object> response = new LinkedHashMap<>();
            response.put("status", "processed");
            response.put("application", "kubewatch-app");
            response.put("processingNote", "Simulated workload for metrics demonstration");
            response.put("timestamp", Instant.now().toString());

            try {
                response.put("hostname", InetAddress.getLocalHost().getHostName());
            } catch (Exception e) {
                response.put("hostname", "unknown");
            }

            return ResponseEntity.ok(response);
        });
    }

    @GetMapping("/api/error-demo")
    public ResponseEntity<Map<String, Object>> errorDemo() {
        errorCounter.increment();

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "error");
        response.put("code", 500);
        response.put("message", "Simulated server error for alerting demonstration");
        response.put("timestamp", Instant.now().toString());

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}
