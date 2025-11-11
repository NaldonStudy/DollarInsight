package com.ssafy.b205.backend.infra.client.google.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class GoogleUserInfoResponse {

    private String sub;
    private String email;
    private Boolean emailVerified;
    private String name;
    private String givenName;
    private String familyName;
    private String picture;
}
