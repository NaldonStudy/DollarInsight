package com.ssafy.b205.backend.domain.chat.controller;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.ChangePaceRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.service.ChatService;
import com.ssafy.b205.backend.support.response.ApiResponse;
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
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/chat")
@Tag(name = "Chat", description = "채팅 세션 생성/메시지 등록/SSE 스트림/중단/히스토리/제어 API")
public class ChatController {

    private final ChatService chatService;

    // 실제 구현에서는 @AuthenticationPrincipal 커스텀 보안 객체에서 userId를 꺼내세요.
    // ※ 서비스가 Integer를 받으므로 여기에서도 Integer로 통일
    private Integer currentUserId(Principal principal) {
        try {
            return Integer.parseInt(principal.getName());
        } catch (NumberFormatException ex) {
            throw new IllegalStateException("Principal name must be numeric userId, but was: " + principal.getName());
        }
    }

    @Operation(
            summary = "세션 생성",
            description = """
                새 채팅 세션을 생성합니다.
                - 메타데이터(Postgres)만 생성되며, 첫 사용자 메시지는 `/sessions/{id}/messages`로 등록합니다.
                - 페르소나는 **요청자가 지정하지 않으며**, 세션 소유 유저의 **활성화된 페르소나 목록 전체**가 자동 연결됩니다.
                - FastAPI에는 첫 메시지 등록 시(`/start`) 해당 페르소나 목록이 전달됩니다.
                """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "성공",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = CreateSessionResponse.class),
                                    examples = @ExampleObject(value = """
                                        {
                                          "data": {
                                            "sessionId": "8c2c2f07-3c3a-4985-8b7d-5f7f7f4e3f21",
                                            "personas": ["Minji","Taeo","Ducksu"],
                                            "createdAt": "2025-11-06T10:12:00"
                                          }
                                        }
                                    """))),
            }
    )
    @PostMapping("/sessions")
    public ApiResponse<CreateSessionResponse> createSession(
            Principal principal,
            @Valid @RequestBody CreateSessionRequest req
    ) {
        return ApiResponse.ok(
                chatService.createSession(currentUserId(principal), req)
        );
    }

    @Operation(
            summary = "사용자 메시지 등록",
            description = """
                사용자 메시지를 등록합니다.
                - 첫 사용자 메시지면 FastAPI `/start` 호출(세션에 연결된 **전체 페르소나 코드 목록**과 함께 전송)
                - 이후 메시지는 `/input`으로 전달
                - 실제 AI 응답은 SSE(`/sessions/{id}/stream`)로 수신
                """,
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @PostMapping("/sessions/{sid}/messages")
    public ApiResponse<AppendMessageResponse> appendMessage(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Valid @RequestBody AppendMessageRequest req
    ) {
        return ApiResponse.ok(
                chatService.appendUserMessage(currentUserId(principal), sessionId, req)
        );
    }

    @Operation(
            summary = "SSE 스트림 시작",
            description = """
                FastAPI의 스트림을 Spring이 게이트웨이로 받아 text/event-stream으로 중계합니다.
                - 이벤트: message, replay, heartbeat, error, interrupted 등
                - 재연결 시 Last-Event-ID 헤더로 일부 이벤트를 replay
                """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "SSE 시작",
                            content = @Content(mediaType = "text/event-stream",
                                    examples = {
                                            @ExampleObject(name = "message", value = """
                                                event: message
                                                data: {"speaker":"Minji","text":"요약을 시작할게요.","turn":1}

                                            """),
                                            @ExampleObject(name = "heartbeat", value = """
                                                event: heartbeat
                                                data: {"ts":"2025-11-06T01:23:45Z"}

                                            """)
                                    }))
            }
    )
    @GetMapping(value = "/sessions/{sid}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
                    description = "디바이스 고유 식별자(UUID v4)") @RequestHeader("X-Device-Id") String deviceId,
            @Parameter(name = "Last-Event-ID", in = ParameterIn.HEADER, required = false,
                    description = "재연결용 이벤트 ID") @RequestHeader(value = "Last-Event-ID", required = false) String lastEventId
    ) {
        return chatService.streamAssistant(currentUserId(principal), sessionId, deviceId, lastEventId);
    }

    @Operation(summary = "중단(인터럽트)",
            description = "현재 진행 중인 스트림을 사용자 주도로 중단합니다.",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "중단 완료") })
    @PostMapping("/sessions/{sid}/interrupt")
    public ResponseEntity<Void> interrupt(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId
    ) {
        chatService.interrupt(currentUserId(principal), sessionId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "히스토리 조회",
            description = "Mongo `chat_messages`에서 최근 N개 메시지를 조회(기본 50)",
            security = @SecurityRequirement(name = "bearerAuth"))
    @GetMapping("/sessions/{sid}/history")
    public ApiResponse<HistoryResponse> history(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Parameter(description = "최근 메시지 개수", example = "50") @RequestParam(defaultValue = "50") int limit
    ) {
        return ApiResponse.ok(
                chatService.history(currentUserId(principal), sessionId, limit)
        );
    }

    @Operation(summary = "스트림 재개 (RESUME)",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "재개 완료") })
    @PostMapping("/sessions/{sid}/control/resume")
    public ResponseEntity<Void> resume(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId
    ) {
        chatService.resume(currentUserId(principal), sessionId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "발화 간격 변경 (CHANGE_PACE)",
            description = "FastAPI에 CHANGE_PACE 명령을 보내 발화 간격(ms)을 변경",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "변경 완료") })
    @PostMapping("/sessions/{sid}/control/pace")
    public ResponseEntity<Void> changePace(
            Principal principal,
            @Parameter(name = "sid", description = "세션 UUID") @PathVariable("sid") UUID sessionId,
            @Valid @RequestBody ChangePaceRequest req
    ) {
        chatService.changePace(currentUserId(principal), sessionId, req.getPaceMs());
        return ResponseEntity.noContent().build();
    }
}
