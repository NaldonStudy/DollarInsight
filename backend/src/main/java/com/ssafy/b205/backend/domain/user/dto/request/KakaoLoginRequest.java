package com.ssafy.b205.backend.domain.user.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class KakaoLoginRequest {

    @Schema(description = "카카오 인가 코드", example = "J9abcdEfg...xyz")
    @NotBlank
    private String code;

    @Schema(description = "클라이언트에서 실제 사용한 redirectUri", example = "kakao123456://oauth")
    private String redirectUri; // null 가능 (서버 기본값 사용)
}
