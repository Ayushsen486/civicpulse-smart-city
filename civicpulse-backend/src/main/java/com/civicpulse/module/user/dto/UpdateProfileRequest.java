package com.civicpulse.module.user.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateProfileRequest(
        @Size(max = 100, message = "First name cannot exceed 100 characters")
        String firstName,

        @Size(max = 100, message = "Last name cannot exceed 100 characters")
        String lastName,

        @Pattern(regexp = "^\\+?[0-9]{10,15}$", message = "Phone must be a valid international or national number")
        String phone,

        UUID wardId,

        String avatarUrl
) {}
