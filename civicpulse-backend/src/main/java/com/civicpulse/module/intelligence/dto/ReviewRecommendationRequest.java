package com.civicpulse.module.intelligence.dto;

import com.civicpulse.module.category.entity.Priority;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record ReviewRecommendationRequest(
        @NotNull(message = "Review action is required (ACCEPT, REJECT, OVERRIDE)")
        ReviewAction action,

        @Size(max = 2000, message = "Review notes cannot exceed 2000 characters")
        String reviewNotes,

        UUID overrideCategoryId,

        Priority overridePriority,

        @Size(max = 100, message = "Override department cannot exceed 100 characters")
        String overrideDepartment,

        Boolean applyToIssue
) {
    public boolean shouldApplyToIssue() {
        return applyToIssue == null || applyToIssue;
    }
}
