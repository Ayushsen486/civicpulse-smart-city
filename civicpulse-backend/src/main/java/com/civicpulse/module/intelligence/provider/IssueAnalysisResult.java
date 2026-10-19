package com.civicpulse.module.intelligence.provider;

import com.civicpulse.module.category.entity.Priority;

import java.util.Map;
import java.util.UUID;

public record IssueAnalysisResult(
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
        boolean needsHumanReview,
        String providerName,
        String providerVersion
) {
}
