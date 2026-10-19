package com.civicpulse.module.auth.dto;

public record GoogleUserPayload(
        String email,
        String firstName,
        String lastName,
        String avatarUrl,
        boolean emailVerified,
        String subject
) {}
