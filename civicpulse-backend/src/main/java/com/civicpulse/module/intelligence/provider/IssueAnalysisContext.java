package com.civicpulse.module.intelligence.provider;

import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;

import java.util.List;
import java.util.UUID;

public record IssueAnalysisContext(
        String title,
        String description,
        UUID currentCategoryId,
        String currentCategorySlug,
        Priority currentPriority,
        String wardName,
        String wardCode,
        Double latitude,
        Double longitude,
        List<Category> availableCategories
) {
    public static IssueAnalysisContext ofDraft(String title, String description, List<Category> availableCategories) {
        return new IssueAnalysisContext(
                title,
                description,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                availableCategories
        );
    }
}
