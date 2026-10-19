package com.civicpulse.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Request payload for Google identity token verification")
public record GoogleLoginRequest(
        @NotBlank(message = "Google ID token must not be blank")
        @Schema(description = "Cryptographically signed Google OAuth2 ID Token from client SDK", example = "eyJhbGciOiJSUzI1NiIs...")
        String idToken
) {}
