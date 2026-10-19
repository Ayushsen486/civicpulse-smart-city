package com.civicpulse.module.ward.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateWardRequest(
        @Size(max = 100, message = "Ward name cannot exceed 100 characters")
        String name,

        @Pattern(regexp = "^[A-Z0-9_-]{2,20}$", message = "Ward code must be 2-20 uppercase alphanumeric, dash, or underscore characters")
        String code,

        String boundaryWkt
) {}
