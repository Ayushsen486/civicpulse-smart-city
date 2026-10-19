package com.civicpulse.module.intelligence.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AnalyzeDraftRequest(
        @NotBlank(message = "Title is required for intelligence suggestion")
        @Size(max = 255, message = "Title must not exceed 255 characters")
        String title,

        @Size(max = 4000, message = "Description must not exceed 4000 characters")
        String description
) {
}
