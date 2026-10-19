package com.civicpulse.module.auth.controller;

import com.civicpulse.common.exception.GlobalExceptionHandler;
import com.civicpulse.common.exception.UnauthorizedException;
import com.civicpulse.module.auth.dto.AuthResponse;
import com.civicpulse.module.auth.dto.LoginRequest;
import com.civicpulse.module.auth.dto.RegisterRequest;
import com.civicpulse.module.auth.service.AuthService;
import com.civicpulse.module.user.dto.UserResponse;
import com.civicpulse.module.user.entity.UserRole;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private AuthService authService;

    @InjectMocks
    private AuthController authController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/auth/register: returns 201 Created on valid registration")
    void register_ValidPayload_Returns201() throws Exception {
        RegisterRequest request = new RegisterRequest(
                "citizen@civicpulse.city",
                "Password123!",
                "Rohan",
                "Gupta",
                "+919876543210"
        );

        UserResponse userResponse = new UserResponse(
                UUID.randomUUID(),
                "citizen@civicpulse.city",
                "+919876543210",
                "Rohan",
                "Gupta",
                UserRole.CITIZEN,
                null,
                true,
                false,
                false,
                null,
                null,
                Instant.now(),
                Instant.now()
        );

        AuthResponse authResponse = AuthResponse.of("mock_access", "mock_refresh", 900L, userResponse);
        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.accessToken").value("mock_access"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.user.email").value("citizen@civicpulse.city"))
                .andExpect(jsonPath("$.meta").exists());
    }

    @Test
    @DisplayName("POST /api/v1/auth/register: returns 400 Bad Request on invalid email")
    void register_InvalidEmail_Returns400() throws Exception {
        RegisterRequest request = new RegisterRequest(
                "invalid-email-format",
                "Password123!",
                "Rohan",
                "Gupta",
                null
        );

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/v1/auth/login: returns 401 Unauthorized on invalid credentials")
    void login_InvalidCredentials_Returns401() throws Exception {
        LoginRequest request = new LoginRequest("citizen@civicpulse.city", "WrongPassword");
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new UnauthorizedException("Invalid email or password"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("POST /api/v1/auth/google: returns 200 OK on valid Google token")
    void googleLogin_ValidToken_Returns200() throws Exception {
        com.civicpulse.module.auth.dto.GoogleLoginRequest request =
                new com.civicpulse.module.auth.dto.GoogleLoginRequest("valid_google_token_123");

        UserResponse userResponse = new UserResponse(
                UUID.randomUUID(),
                "googleuser@civicpulse.city",
                null,
                "Asha",
                "Patel",
                UserRole.CITIZEN,
                "https://lh3.googleusercontent.com/avatar.jpg",
                true,
                false,
                true,
                null,
                null,
                Instant.now(),
                Instant.now()
        );

        AuthResponse authResponse = AuthResponse.of("mock_google_access", "mock_google_refresh", 900L, userResponse);
        when(authService.loginWithGoogle(any(com.civicpulse.module.auth.dto.GoogleLoginRequest.class)))
                .thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").value("mock_google_access"))
                .andExpect(jsonPath("$.data.user.email").value("googleuser@civicpulse.city"))
                .andExpect(jsonPath("$.data.user.role").value("CITIZEN"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/google: returns 400 Bad Request on blank idToken")
    void googleLogin_BlankToken_Returns400() throws Exception {
        com.civicpulse.module.auth.dto.GoogleLoginRequest request =
                new com.civicpulse.module.auth.dto.GoogleLoginRequest("   ");

        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
