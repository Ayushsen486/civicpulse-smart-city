package com.civicpulse.module.auth.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.module.auth.dto.AuthResponse;
import com.civicpulse.module.auth.dto.GoogleLoginRequest;
import com.civicpulse.module.auth.dto.LoginRequest;
import com.civicpulse.module.auth.dto.RefreshTokenRequest;
import com.civicpulse.module.auth.dto.RegisterRequest;
import com.civicpulse.module.auth.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Authentication and token lifecycle endpoints")
public class AuthController {

    private final AuthService AuthService;

    public AuthController(AuthService AuthService) {
        this.AuthService = AuthService;
    }

    @PostMapping("/google")
    @Operation(summary = "Google Sign-In", description = "Authenticates or registers a citizen using a cryptographically verified Google ID token")
    public ResponseEntity<ApiResponse<AuthResponse>> googleLogin(@Valid @RequestBody GoogleLoginRequest request) {
        AuthResponse response = AuthService.loginWithGoogle(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/register")
    @Operation(summary = "Citizen self-registration", description = "Registers a new citizen user account with email and password")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = AuthService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticates user with email and password and returns access/refresh tokens")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = AuthService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token", description = "Issues a new access token and rotated refresh token using an active refresh token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = AuthService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/logout")
    @Operation(summary = "User logout", description = "Revokes the provided refresh token session")
    public ResponseEntity<ApiResponse<Map<String, String>>> logout(@Valid @RequestBody RefreshTokenRequest request) {
        AuthService.logout(request);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Logged out successfully")));
    }
}
