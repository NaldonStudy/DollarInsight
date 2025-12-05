package com.ssafy.b205.backend.domain.user.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class GoogleLoginRequest {

    @Schema(description = "구글 OAuth 인가 코드", example = "4/0AbCdEfGhIjKlMn...")
    @NotBlank
    private String code;

    @Schema(description = "클라이언트에서 사용한 redirectUri", example = "com.dollarinsight.app:/oauth2redirect/google")
    private String redirectUri;

    @Schema(description = "PKCE code_verifier (인가 요청 시 사용한 값)", example = "a1b2c3d4e5f6g7h8i9j0")
    @NotBlank
    private String codeVerifier;
}
