package com.civicpulse.module.category.dto;

import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String name,
        String slug,
        String icon,
        String color,
        Priority defaultPriority,
        Integer slaHoursOverride,
        boolean isActive,
        UUID parentId,
        String parentName,
        int sortOrder,
        List<CategoryResponse> subCategories,
        Instant createdAt,
        Instant updatedAt
) {
    public static CategoryResponse fromEntity(Category category) {
        if (category == null) {
            return null;
        }
        UUID parentId = null;
        String parentName = null;
        if (category.getParent() != null) {
            parentId = category.getParent().getId();
            parentName = category.getParent().getName();
        }

        List<CategoryResponse> subList = Collections.emptyList();
        if (category.getSubCategories() != null && !category.getSubCategories().isEmpty()) {
            subList = category.getSubCategories().stream()
                    .map(CategoryResponse::fromEntity)
                    .toList();
        }

        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getSlug(),
                category.getIcon(),
                category.getColor(),
                category.getDefaultPriority(),
                category.getSlaHoursOverride(),
                category.isActive(),
                parentId,
                parentName,
                category.getSortOrder(),
                subList,
                category.getCreatedAt(),
                category.getUpdatedAt()
        );
    }
}
