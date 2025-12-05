package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.auth.service.AuthApplicationService;
import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;
    @MockitoBean
    private AuthApplicationService authApplicationService;
    @MockitoBean
    private TokenProvider tokenProvider;

    @Test
    void signupReturnsTokenPair() throws Exception {
        when(authApplicationService.signupAndIssue(any(SignupRequest.class), any(String.class)))
                .thenReturn(new TokenPairResponse("access", "refresh"));

        mockMvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "user@example.com",
                                  "nickname": "User",
                                  "password": "Aa1!aaaa",
                                  "pushEnabled": true
                                }
                                """)
                        .header("X-Device-Id", "device-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ok").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("access"))
                .andExpect(jsonPath("$.data.refreshToken").value("refresh"));

        ArgumentCaptor<SignupRequest> captor = ArgumentCaptor.forClass(SignupRequest.class);
        verify(authApplicationService).signupAndIssue(captor.capture(), any(String.class));
        assertThat(captor.getValue().getEmail()).isEqualTo("user@example.com");
    }

    @Test
    void loginReturnsTokenPair() throws Exception {
        when(authApplicationService.loginAndIssue(any(LoginRequest.class), any(String.class)))
                .thenReturn(new TokenPairResponse("acc", "ref"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "user@example.com",
                                  "password": "Password1!"
                                }
                                """)
                        .header("X-Device-Id", "device-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ok").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("acc"))
                .andExpect(jsonPath("$.data.refreshToken").value("ref"));
    }

    @Test
    void requestsWithoutDeviceHeaderFailValidation() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "user@example.com",
                                  "password": "Password1!"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }
}
