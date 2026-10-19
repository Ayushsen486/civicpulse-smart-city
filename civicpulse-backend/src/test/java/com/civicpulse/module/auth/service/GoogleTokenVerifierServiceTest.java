package com.civicpulse.module.auth.service;

import com.civicpulse.common.exception.UnauthorizedException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoogleTokenVerifierServiceTest {

    private GoogleTokenVerifierService verifierService;

    @BeforeEach
    void setUp() {
        verifierService = new GoogleTokenVerifierService("test-client-id");
    }

    @Test
    @DisplayName("verifyToken: throws UnauthorizedException when token is null or blank")
    void verifyToken_Blank_ThrowsUnauthorized() {
        assertThatThrownBy(() -> verifierService.verifyToken(null))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("missing or empty");

        assertThatThrownBy(() -> verifierService.verifyToken("   "))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("missing or empty");
    }

    @Test
    @DisplayName("verifyToken: throws UnauthorizedException when token is invalid or malformed")
    void verifyToken_Malformed_ThrowsUnauthorized() {
        assertThatThrownBy(() -> verifierService.verifyToken("invalid.jwt.token"))
                .isInstanceOf(UnauthorizedException.class);
    }
}
