package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.LocalDate;

@Getter
public class DailyPickResponse {

    @Schema(description = "상세 화면 이동용 티커")
    private final String ticker;

    @Schema(description = "추천 종목(또는 기업) 이름")
    private final String companyName;

    @Schema(description = "산업/비즈니스 요약 문구")
    private final String companyInfo;

    @Schema(description = "AI 분석 기준 일자")
    private final LocalDate analyzedDate;

    @Schema(description = "선택된 페르소나의 코멘트")
    private final PersonaCommentResponse personaComment;

    public DailyPickResponse(String ticker,
                             String companyName,
                             String companyInfo,
                             LocalDate analyzedDate,
                             PersonaCommentResponse personaComment) {
        this.ticker = ticker;
        this.companyName = companyName;
        this.companyInfo = companyInfo;
        this.analyzedDate = analyzedDate;
        this.personaComment = personaComment;
    }
}
