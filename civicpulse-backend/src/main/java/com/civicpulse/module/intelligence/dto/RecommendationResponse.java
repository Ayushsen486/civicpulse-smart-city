package com.civicpulse.module.intelligence.dto;

import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.intelligence.entity.IssueRecommendation;
import com.civicpulse.module.intelligence.entity.ReviewStatus;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;

public record RecommendationResponse(
        UUID id,
        UUID issueId,
        UUID suggestedCategoryId,
        String suggestedCategoryName,
        Priority suggestedPriority,
        String recommendedDepartment,
        double categoryConfidence,
        double priorityConfidence,
        double routingConfidence,
        double overallConfidence,
        String explanation,
        Map<String, Object> factors,
        String providerName,
        String providerVersion,
        boolean needsHumanReview,
        ReviewStatus reviewStatus,
        UUID reviewedById,
        String reviewedByName,
        Instant reviewedAt,
        String reviewNotes,
        UUID overrideCategoryId,
        String overrideCategoryName,
        Priority overridePriority,
        String overrideDepartment,
        boolean isCurrent,
        Instant createdAt,
        Instant updatedAt
) {
    public static RecommendationResponse fromEntity(IssueRecommendation entity, ObjectMapper objectMapper) {
        Map<String, Object> factorsMap = Collections.emptyMap();
        if (entity.getFactors() != null && !entity.getFactors().isBlank() && objectMapper != null) {
            try {
                factorsMap = objectMapper.readValue(entity.getFactors(), new TypeReference<>() {});
            } catch (Exception e) {
                factorsMap = Collections.singletonMap("raw", entity.getFactors());
            }
        }

        String reviewerName = null;
        UUID reviewerId = null;
        if (entity.getReviewedBy() != null) {
            reviewerId = entity.getReviewedBy().getId();
            reviewerName = entity.getReviewedBy().getFirstName() + " " + entity.getReviewedBy().getLastName();
        }

        String suggestedCategoryName = entity.getSuggestedCategory() != null
                ? entity.getSuggestedCategory().getName()
                : null;

        String overrideCategoryName = entity.getOverrideCategory() != null
                ? entity.getOverrideCategory().getName()
                : null;

        return new RecommendationResponse(
                entity.getId(),
                entity.getIssue().getId(),
                entity.getSuggestedCategory() != null ? entity.getSuggestedCategory().getId() : null,
                suggestedCategoryName,
                entity.getSuggestedPriority(),
                entity.getRecommendedDepartment(),
                entity.getCategoryConfidence(),
                entity.getPriorityConfidence(),
                entity.getRoutingConfidence(),
                entity.getOverallConfidence(),
                entity.getExplanation(),
                factorsMap,
                entity.getProviderName(),
                entity.getProviderVersion(),
                entity.isNeedsHumanReview(),
                entity.getReviewStatus(),
                reviewerId,
                reviewerName,
                entity.getReviewedAt(),
                entity.getReviewNotes(),
                entity.getOverrideCategory() != null ? entity.getOverrideCategory().getId() : null,
                overrideCategoryName,
                entity.getOverridePriority(),
                entity.getOverrideDepartment(),
                entity.isCurrent(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
