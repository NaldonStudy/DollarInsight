package com.ssafy.b205.backend.infra.client.fastai;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

@ConfigurationProperties(prefix = "fastai")
public class FastAiProperties {

    private final String baseUrl;
    private final int connectTimeoutMs;
    private final int readTimeoutMs;

    @ConstructorBinding
    public FastAiProperties(String baseUrl, int connectTimeoutMs, int readTimeoutMs) {
        this.baseUrl = baseUrl;
        this.connectTimeoutMs = connectTimeoutMs;
        this.readTimeoutMs = readTimeoutMs;
    }

    public String getBaseUrl() { return baseUrl; }
    public int getConnectTimeoutMs() { return connectTimeoutMs; }
    public int getReadTimeoutMs() { return readTimeoutMs; }
}
