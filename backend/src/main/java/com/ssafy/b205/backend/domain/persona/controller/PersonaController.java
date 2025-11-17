package com.ssafy.b205.backend.domain.persona.controller;

import com.ssafy.b205.backend.domain.persona.dto.PersonaResponse;
import com.ssafy.b205.backend.domain.persona.service.PersonaQueryService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/personas")
@RequiredArgsConstructor
@Tag(name = "Personas", description = "페르소나 메타데이터 조회 API")
@SecurityRequirement(name = "bearerAuth")
public class PersonaController {

    private final PersonaQueryService personaQueryService;

    @Operation(
            summary = "전체 페르소나 목록",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = PersonaResponse.class),
                                    examples = @ExampleObject(value = """
                                        [
                                          { "id": 1, "code": "Minji" },
                                          { "id": 2, "code": "Taeo" },
                                          { "id": 3, "code": "Ducksu" }
                                        ]
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping
    public ApiResponse<java.util.List<PersonaResponse>> listAll() {
        final var personas = personaQueryService.findAll().stream()
                .map(PersonaResponse::from)
                .toList();
        return ApiResponse.ok(personas);
    }
}
