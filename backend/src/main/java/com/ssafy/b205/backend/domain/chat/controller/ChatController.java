package com.ssafy.b205.backend.domain.chat.controller;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.ChangePaceRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.service.ChatService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/chat")
@Tag(name = "Chat", description = "채팅 세션 생성/메시지 등록/SSE 스트림/중단/히스토리/제어 API")
public class ChatController {

    private final ChatService chatService;

    // ---------------------------------------------------------------------
    // 1) 세션 생성
    // ---------------------------------------------------------------------
    @Operation(
            summary = "세션 생성",
            description = """
            새 채팅 세션 메타데이터(PostgreSQL)를 생성합니다. 
            첫 사용자 메시지는 `/api/chat/sessions/{sid}/messages`로 전송하세요.
            
            • 인증: Bearer AccessToken
            • 필수 헤더: `X-Device-Id`(UUID v4) — 토큰의 did 클레임과 일치해야 함
            """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "세션 생성 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = CreateSessionResponse.class),
                            examples = @ExampleObject(name = "ok", value = """
                    {
                      "sessionUuid": "4b1c0a5c-2c4c-49d9-8c8f-19b6e0a6a1d2",
                      "personas": ["Minji","Taeo","Ducksu"],
                      "createdAt": "2025-11-07T04:50:00Z"
                    }
                """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "권한 없음"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "요청 본문 오류")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/sessions")
    public ApiResponse<CreateSessionResponse> createSession(
            @AuthenticationPrincipal String userUuid,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = CreateSessionRequest.class),
                            examples = {
                                    @ExampleObject(name = "custom", value = """
                        { "topicType": "CUSTOM", "title": "엔비디아 전망 토크" }
                    """),
                                    @ExampleObject(name = "company", value = """
                        { "topicType": "COMPANY", "title": "애플 실적 콜 분석", "ticker": "AAPL" }
                    """)
                            }
                    )
            )
            @Valid @RequestBody CreateSessionRequest req
    ) {
        return ApiResponse.ok(chatService.createSession(userUuid, req));
    }

    // ---------------------------------------------------------------------
    // 2) 사용자 메시지 등록
    // ---------------------------------------------------------------------
    @Operation(
            summary = "사용자 메시지 등록",
            description = """
            세션에 사용자 메시지를 추가합니다.
            
            • 첫 사용자 메시지면 FastAPI `/start` 호출(세션의 페르소나 코드 전달)  
            • 이후 메시지는 FastAPI `/input`으로 전달되어 SSE로 응답 수신  
            • 인증: Bearer AccessToken  
            • 필수 헤더: `X-Device-Id`
            """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "등록 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = AppendMessageResponse.class),
                            examples = @ExampleObject(value = """
                    { "messageId": "672c1fe28f7d3c0b1d2a90a3" }
                """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "요청 본문 오류")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/sessions/{sid}/messages")
    public ApiResponse<AppendMessageResponse> appendMessage(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = AppendMessageRequest.class),
                            examples = @ExampleObject(value = """
                    { "content": "내 월급일·연금 일정 기준으로 포트폴리오 다시 짜줘" }
                """)
                    )
            )
            @Valid @RequestBody AppendMessageRequest req
    ) {
        return ApiResponse.ok(chatService.appendUserMessage(userUuid, sessionId, req));
    }

    // ---------------------------------------------------------------------
    // 3) SSE 스트림
    // ---------------------------------------------------------------------
    @Operation(
            summary = "SSE 스트림 시작",
            description = """
            해당 세션의 AI 응답을 Server-Sent Events로 스트리밍합니다.
            
            • 요청 헤더:  
              - `Accept: text/event-stream`  
              - `X-Device-Id`(필수)  
              - `Last-Event-ID`(옵션, 재연결 시)
            
            • 이벤트 타입:  
              - `message`(토큰/문장 청크)  
              - `done`(완료)  
              - `error`(오류)
            """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "스트림 시작",
                    content = @Content(mediaType = "text/event-stream")
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음")
    })
    @GetMapping(value = "/sessions/{sid}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
                    description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
            @RequestHeader("X-Device-Id") String deviceId,
            @Parameter(name = "Last-Event-ID", in = ParameterIn.HEADER, required = false,
                    description = "SSE 재연결용 마지막 이벤트 ID(옵션)", example = "128")
            @RequestHeader(value = "Last-Event-ID", required = false) String lastEventId
    ) {
        return chatService.streamAssistant(userUuid, sessionId, deviceId, lastEventId);
    }

    // ---------------------------------------------------------------------
    // 4) 중단/재개/속도 제어
    // ---------------------------------------------------------------------
    @Operation(
            summary = "중단(인터럽트)",
            description = "진행 중인 스트림에 `INTERRUPT` 제어 신호를 보냅니다.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "중단 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/sessions/{sid}/interrupt")
    public ResponseEntity<Void> interrupt(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId
    ) {
        chatService.interrupt(userUuid, sessionId);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "스트림 재개 (RESUME)",
            description = "`RESUME` 제어 신호를 전송하여 일시 중단된 스트림을 재개합니다.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "재개 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/sessions/{sid}/control/resume")
    public ResponseEntity<Void> resume(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId
    ) {
        chatService.resume(userUuid, sessionId);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "발화 간격 변경 (CHANGE_PACE)",
            description = "`CHANGE_PACE`(pace_ms) 제어 신호로 스트리밍 속도를 조절합니다.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "변경 성공"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "요청 본문 오류")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/sessions/{sid}/control/pace")
    public ResponseEntity<Void> changePace(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = ChangePaceRequest.class),
                            examples = @ExampleObject(value = """
                    { "paceMs": 2000 }
                """)
                    )
            )
            @Valid @RequestBody ChangePaceRequest req
    ) {
        chatService.changePace(userUuid, sessionId, req.getPaceMs());
        return ResponseEntity.noContent().build();
    }

    // ---------------------------------------------------------------------
    // 5) 히스토리 조회 (v1: ts 기반, 간단 조회)
    // ---------------------------------------------------------------------
    @Operation(
            summary = "히스토리 조회 (v1: ts 기반, 간단 조회)",
            description = """
            세션의 과거 대화를 **최근→과거로 조회한 뒤 과거→최신**으로 반환합니다.
            
            ■ v1 특징(프론트 안내)
            - 정렬 기준: `ts`(시간) 기반
            - 파라미터: `limit`만 지원 (기본=50), **커서 없음**
            - 응답: `items` 배열만 존재 (페이지네이션 메타 없음)
            - 사용처: 간단한 최근 N개 조회/초기 MVP
            
            👉 무한스크롤/안정적 페이지네이션이 필요하면 **v2** 사용을 권장합니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "조회 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = HistoryResponse.class),
                            examples = @ExampleObject(value = """
                    {
                      "items": [
                        { "role": "user", "content": "포지션 요약해줘", "ts": "2025-11-07T04:51:01Z" },
                        { "role": "assistant", "content": "요약: ...", "ts": "2025-11-07T04:51:03Z" }
                      ]
                    }
                """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping("/sessions/{sid}/history")
    public ApiResponse<HistoryResponse> history(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId,
            @Parameter(description = "최근 메시지 개수(기본=50)", example = "50")
            @RequestParam(defaultValue = "50") int limit
    ) {
        return ApiResponse.ok(chatService.history(userUuid, sessionId, limit));
    }

    // ---------------------------------------------------------------------
    // 6) 히스토리 조회 (v2: _id 커서 기반 페이지네이션)
    // ---------------------------------------------------------------------
    @Operation(
            summary = "히스토리 조회 (v2: _id 커서 기반 페이지네이션)",
            description = """
            세션의 과거 대화를 **Mongo `_id` 커서**로 안정적으로 페이지네이션하여 반환합니다.
            응답은 **과거→최신** 순서로 제공되며, `nextCursor`와 `hasMore`로 이어보기 동작을 구현합니다.
            
            ■ v2 특징(프론트 안내 — 무한스크롤 표준)
            - 정렬/커서: Mongo `_id`(단조증가) 기반 — **중복·충돌 없이 안정적**
            - 파라미터: 
              • `limit` (1~100, 기본=50)  
              • `cursor` (이전 응답의 `nextCursor`, 없으면 첫 페이지)
            - 응답: 
              • `items` (과거→최신)  
              • `nextCursor` (다음 페이지 조회 시 전달)  
              • `hasMore` (다음 페이지 존재 여부)
            - 권장 사용처: **무한스크롤/모바일 대화 히스토리**
            
            ■ 마이그레이션 가이드
            1) 최초 호출: `/history2?limit=50` (cursor 없음)  
            2) 다음 호출: `/history2?limit=50&cursor=<직전 nextCursor>`  
            3) `hasMore=false`일 때 리스트 끝 처리
            """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "조회 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = HistoryCursorResponse.class),
                            examples = @ExampleObject(value = """
                    {
                      "items": [
                        { "id": "6750f9c7d9a1f2b345678901", "role": "user", "content": "최근 대화 요약", "ts": "2025-11-09T09:00:01Z" },
                        { "id": "6750f9c7d9a1f2b345678902", "role": "assistant", "content": "요약입니다: ...", "ts": "2025-11-09T09:00:03Z" }
                      ],
                      "nextCursor": "6750f9c7d9a1f2b345678902",
                      "hasMore": true
                    }
                """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "인증 실패"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "세션 소유자 불일치"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "세션 없음")
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping("/sessions/{sid}/history2")
    public ApiResponse<HistoryCursorResponse> history2(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId,
            @Parameter(description = "페이지 크기(1~100, 기본=50)", example = "50")
            @RequestParam(name = "limit", defaultValue = "50") int limit,
            @Parameter(description = "이전 응답에서 받은 nextCursor(_id), 없으면 첫 페이지", example = "6750f9c7d9a1f2b345678902")
            @RequestParam(name = "cursor", required = false) String cursor
    ) {
        return ApiResponse.ok(chatService.history2(userUuid, sessionId, limit, cursor));
    }
}
