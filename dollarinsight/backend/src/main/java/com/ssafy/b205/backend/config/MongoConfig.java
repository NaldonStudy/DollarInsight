package com.ssafy.b205.backend.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.data.convert.ReadingConverter;
import org.springframework.data.mongodb.core.convert.MongoCustomConversions;
import org.springframework.util.StringUtils;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@Configuration
public class MongoConfig {

    @Bean
    public MongoCustomConversions mongoCustomConversions() {
        return new MongoCustomConversions(List.of(new StringToInstantConverter()));
    }

    @ReadingConverter
    static class StringToInstantConverter implements Converter<String, Instant> {
        private static final Logger log = LoggerFactory.getLogger(StringToInstantConverter.class);
        private static final DateTimeFormatter LEGACY_FORMAT =
                DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        @Override
        public Instant convert(String source) {
            if (!StringUtils.hasText(source)) {
                return null;
            }
            String value = source.trim();
            try {
                return Instant.parse(value);
            } catch (DateTimeParseException ignored) {
                // fall through to legacy format
            }
            try {
                LocalDateTime localDateTime = LocalDateTime.parse(value, LEGACY_FORMAT);
                return localDateTime.toInstant(ZoneOffset.UTC);
            } catch (DateTimeParseException ex) {
                log.warn("[MongoCfg-W01] Failed to parse Mongo date value: {}", value, ex);
                return null;
            }
        }
    }
}
