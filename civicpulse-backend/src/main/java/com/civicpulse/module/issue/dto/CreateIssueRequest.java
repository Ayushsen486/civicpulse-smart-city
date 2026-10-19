package com.civicpulse.module.issue.dto;

import com.civicpulse.module.category.entity.Priority;
import jakarta.validation.constraints.*;

import java.util.UUID;

public record CreateIssueRequest(
        @NotBlank(message = "Title is required")
        @Size(max = 255, message = "Title cannot exceed 255 characters")
        String title,

        String description,

        @NotNull(message = "Category is required")
        UUID categoryId,

        Priority priority,

        @NotNull(message = "Latitude is required")
        @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
        @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
        Double latitude,

        @NotNull(message = "Longitude is required")
        @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
        @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
        Double longitude,

        String address,

        @Size(max = 255, message = "Landmark cannot exceed 255 characters")
        String landmark
) {}
