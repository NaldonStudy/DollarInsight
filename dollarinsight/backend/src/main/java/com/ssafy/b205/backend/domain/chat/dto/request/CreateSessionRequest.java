package com.ssafy.b205.backend.domain.chat.dto.request;

import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class CreateSessionRequest {

    @Schema(example = "CUSTOM") // COMPANY | NEWS | CUSTOM
    @NotNull
    private ChatTopicType topicType;

    @Schema(example = "엔비디아 전망 토크")
    @Size(max = 256)
    private String title;

    // 선택: COMPANY 세션일 때만 필수
    @Schema(example = "NVDA")
    private String ticker;

    // 선택: NEWS 세션이면 지정 가능(없으면 null)
    @Schema(example = "123")
    private Long companyNewsId;

    @AssertTrue(message = "topicType=COMPANY인 경우 ticker가 필요합니다.")
    public boolean isCompanyValid() {
        return topicType != ChatTopicType.COMPANY
                || (ticker != null && !ticker.isBlank());
    }
}
