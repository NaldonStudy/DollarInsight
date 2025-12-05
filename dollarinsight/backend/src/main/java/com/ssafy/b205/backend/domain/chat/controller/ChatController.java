package com.ssafy.b205.backend.domain.chat.controller;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.ChangePaceRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.ChatSessionSummaryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.service.ChatService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import com.ssafy.b205.backend.support.response.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
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
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
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
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "등록 성공",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = AppendMessageResponse.class),
                                    examples = @ExampleObject(value = """
                                    { "messageId": "672c1fe28f7d3c0b1d2a90a3" }
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
    // 3) 세션 목록
    // ---------------------------------------------------------------------
    @Operation(
            summary = "세션 목록 조회",
            description = """
            사용자가 생성한 채팅 세션을 페이지네이션으로 조회합니다.
            가장 최근에 상호작용한 세션(updated_at 내림차순)부터 반환합니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "목록 조회 성공",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = PageResponse.class),
                                    examples = @ExampleObject(name = "ok", value = """
                                        {
                                          "items": [
                                            {
                                              "sessionUuid": "4b1c0a5c-2c4c-49d9-8c8f-19b6e0a6a1d2",
                                              "topicType": "CUSTOM",
                                              "title": "엔비디아 전망 토크",
                                              "ticker": "NVDA",
                                              "companyNewsId": null,
                                              "createdAt": "2025-11-07T04:50:00Z",
                                              "updatedAt": "2025-11-07T05:00:00Z"
                                            }
                                          ],
                                          "page": 0,
                                          "size": 20,
                                          "totalElements": 1,
                                          "totalPages": 1,
                                          "hasNext": false
                                        }
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping("/sessions")
    public ApiResponse<PageResponse<ChatSessionSummaryResponse>> listSessions(
            @AuthenticationPrincipal String userUuid,
            @Parameter(description = "페이지 번호(0부터)", example = "0")
            @RequestParam(name = "page", defaultValue = "0") int page,
            @Parameter(description = "페이지 크기(1~100, 기본 20)", example = "20")
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        return ApiResponse.ok(chatService.listSessions(userUuid, page, size));
    }

    // ---------------------------------------------------------------------
    // 4) 세션 삭제
    // ---------------------------------------------------------------------
    @Operation(
            summary = "세션 삭제",
            description = """
            세션 메타데이터(PostgreSQL)만 소프트 삭제합니다.
            Mongo 히스토리는 보관되지만 더 이상 목록/조회에 노출되지 않습니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "삭제 성공"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @DeleteMapping("/sessions/{sid}")
    public ResponseEntity<Void> deleteSession(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId
    ) {
        chatService.deleteSession(userUuid, sessionId);
        return ResponseEntity.noContent().build();
    }

    // ---------------------------------------------------------------------
    // 5) SSE 스트림
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
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "스트림 시작",
                            content = @Content(mediaType = "text/event-stream")
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @GetMapping(value = "/sessions/{sid}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = false,
                    description = "디바이스 식별자(UUID v4, 헤더 또는 쿼리 파라미터 device_id)", example = "11111111-1111-1111-1111-111111111111")
            @RequestHeader(value = "X-Device-Id", required = false) String deviceIdHeader,
            @Parameter(name = "device_id", in = ParameterIn.QUERY, required = false,
                    description = "디바이스 식별자(UUID v4, SSE용 쿼리 파라미터)", example = "11111111-1111-1111-1111-111111111111")
            @RequestParam(value = "device_id", required = false) String deviceIdParam,
            @Parameter(name = "Last-Event-ID", in = ParameterIn.HEADER, required = false,
                    description = "SSE 재연결용 마지막 이벤트 ID(옵션)", example = "128")
            @RequestHeader(value = "Last-Event-ID", required = false) String lastEventId
    ) {
        // 헤더 또는 쿼리 파라미터에서 deviceId 가져오기
        String deviceId = (deviceIdHeader != null && !deviceIdHeader.isBlank())
                ? deviceIdHeader
                : deviceIdParam;
        return chatService.streamAssistant(userUuid, sessionId, deviceId, lastEventId);
    }

    // ---------------------------------------------------------------------
    // 6) 중단/재개/속도 제어
    // ---------------------------------------------------------------------
    @Operation(
            summary = "중단(인터럽트)",
            description = "진행 중인 스트림에 `STOP` 제어 신호를 보냅니다. (FastAPI의 STOP 액션 사용)",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "중단 성공"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "재개 성공"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "변경 성공"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
    // 7) 히스토리 조회 (v1: ts 기반)
    // ---------------------------------------------------------------------
    @Operation(
            summary = "히스토리 조회 (v1: ts 기반, 간단 조회)",
            description = """
            세션의 과거 대화를 **최근→과거로 조회한 뒤 과거→최신**으로 반환합니다.
            (커서 없음; limit만 지원. 간단 조회용)
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
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
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
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
    // 8) 히스토리 조회 (v2: _id 커서 기반)
    // ---------------------------------------------------------------------
    @Operation(
            summary = "히스토리 조회 (v2: _id 커서 기반 페이지네이션)",
            description = """
            Mongo `_id` 커서를 활용해 과거→최신 순서로 페이지네이션합니다.
            `nextCursor`와 `hasMore`로 무한스크롤을 구현합니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
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
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4)", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping("/sessions/{sid}/history2")
    public ApiResponse<HistoryCursorResponse> history2(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid") @PathVariable("sid") UUID sessionId,
            @Parameter(description = "페이지 크기(1~100, 기본=50)", example = "50")
            @RequestParam(name = "limit", defaultValue = "50") int limit,
            @Parameter(description = "이전 응답의 nextCursor(_id), 없으면 첫 페이지", example = "6750f9c7d9a1f2b345678902")
            @RequestParam(name = "cursor", required = false) String cursor
    ) {
        return ApiResponse.ok(chatService.history2(userUuid, sessionId, limit, cursor));
    }
}
