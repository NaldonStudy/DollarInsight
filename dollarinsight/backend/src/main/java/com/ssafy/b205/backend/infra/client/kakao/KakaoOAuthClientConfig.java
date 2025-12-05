package com.ssafy.b205.backend.infra.client.kakao;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Configuration
@EnableConfigurationProperties(KakaoOAuthProperties.class)
public class KakaoOAuthClientConfig {

    @Bean(name = "kakaoWebClient")
    public WebClient kakaoWebClient(KakaoOAuthProperties props) {
        HttpClient http = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, props.getTimeoutSeconds() * 1000)
                .responseTimeout(Duration.ofSeconds(props.getTimeoutSeconds()))
                .doOnConnected(conn -> conn.addHandlerLast(
                        new ReadTimeoutHandler(props.getTimeoutSeconds(), TimeUnit.SECONDS)));

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(http))
                .exchangeStrategies(ExchangeStrategies.builder()
                        .codecs(c -> c.defaultCodecs().maxInMemorySize(8 * 1024 * 1024))
                        .build())
                .build();
    }
}
