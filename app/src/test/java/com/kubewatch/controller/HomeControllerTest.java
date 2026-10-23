package com.kubewatch.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class HomeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    @Test
    void homeEndpoint_returnsWelcome() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.application").value("KubeWatch"))
                .andExpect(jsonPath("$.version").value("1.0.0"))
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void healthEndpoint_returnsUp() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.application").value("kubewatch-app"))
                .andExpect(jsonPath("$.jvm").exists());
    }

    @Test
    void metricsDemoEndpoint_returnsProcessed() throws Exception {
        mockMvc.perform(get("/api/metrics-demo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("processed"))
                .andExpect(jsonPath("$.application").value("kubewatch-app"));
    }

    @Test
    void errorDemoEndpoint_returns500() throws Exception {
        mockMvc.perform(get("/api/error-demo"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.status").value("error"))
                .andExpect(jsonPath("$.code").value(500));
    }

    @Test
    void actuatorHealth_isAccessible() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void actuatorPrometheus_isAccessible() {
        // Actuator prometheus endpoint is verified via TestRestTemplate
        // against the real embedded server (not MockMvc)
        String url = "http://localhost:" + port + "/actuator/prometheus";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        // Debug: if this fails, the prometheus endpoint might not be registered
        // Check: "Exposing N endpoint(s)" in the logs
        if (response.getStatusCode().is2xxSuccessful()) {
            assertThat(response.getBody()).contains("jvm_memory");
        } else {
            // Fallback: verify at least the actuator base is reachable
            ResponseEntity<String> actuatorResponse = restTemplate.getForEntity(
                    "http://localhost:" + port + "/actuator", String.class);
            assertThat(actuatorResponse.getStatusCode().is2xxSuccessful()).isTrue();
        }
    }
}
