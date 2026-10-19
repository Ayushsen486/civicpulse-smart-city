package com.civicpulse.module.intelligence.dto;

import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.intelligence.provider.IssueAnalysisResult;

import java.util.UUID;

public record DraftAnalysisResponse(
        UUID suggestedCategoryId,
        String suggestedCategoryName,
        Priority suggestedPriority,
        String recommendedDepartment,
        double categoryConfidence,
        double priorityConfidence,
        double overallConfidence,
        String explanation,
        boolean needsHumanReview
) {
    public static DraftAnalysisResponse fromResult(IssueAnalysisResult result) {
        return new DraftAnalysisResponse(
                result.suggestedCategoryId(),
                result.suggestedCategoryName(),
                result.suggestedPriority(),
                result.recommendedDepartment(),
                result.categoryConfidence(),
                result.priorityConfidence(),
                result.overallConfidence(),
                result.explanation(),
                result.needsHumanReview()
        );
    }
}
